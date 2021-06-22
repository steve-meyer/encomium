module Encomium
  class DataSet


    TABLES = {
      "journals"              => ["id", "title", "issn", "eissn", "lc_classes", "publisher_id"],
      "categories"            => ["id", "name"],
      "categories_journals"   => ["category_id", "journal_id"],
      "collections"           => ["id", "name"],
      "collections_journals"  => ["collection_id", "journal_id"],
      "publishers"            => ["id", "name"],
      "publication_summaries" => ["id", "journal_id", "date", "institution", "article_count", "grant_article_count"],
      "use_summaries"         => ["id", "journal_id", "date", "institution", "use_count"],
      "citation_summaries"    => ["id", "journal_id", "date", "institution", "citation_count"],
      "grants"                => ["id", "identifiers", "institution", "grant_agency_name"],
      "agencies"              => ["id", "name"],
      "agencies_grants"       => ["agency_id", "grant_id"],
      "grants_journals"       => ["grant_id", "journal_id"],
      "lc_classifications"    => ["id", "normalized_subject", "lj_subject", "section", "code", "range_start", "range_end", "group_1", "group_2", "group_3", "group_4", "group_5"],
      "journals_lc_classifications" => ["journal_id", "lc_classification_id"]
    }


    def initialize(journalid_index, output_dir)
      @journalid_index = journalid_index
      @output_dir      = output_dir
    end


    def generate_analysis_csv
      summary_output = @output_dir + "/combined-data-summary.csv"
      monthly_output = @output_dir + "/combined-data-monthly.csv"
      @summary_csv = CSV.open(summary_output, "w+", headers: summary_headers, write_headers: true)
      @monthly_csv = CSV.open(monthly_output, "w+", headers: monthly_headers, write_headers: true)
      process_journals
      @summary_csv.close
      @monthly_csv.close
    end


    def generate_tables
      load_lc_class_data
      open_table_files
      setup_lookup_tables
      setup_grants_tables
      generate_table_files
      close_table_files
    end


    private


    def load_lc_class_data
      config_dir = File.expand_path(File.dirname(__FILE__) + "../../../config/")

      top_classifications_file = config_dir + "/lc_top_classifications.yml"
      @top_classificaitons = YAML.load_file(top_classifications_file)

      lc_classifications_file = config_dir + "/lc-classifications.csv"
      lc_normalizations_file  = config_dir + "/lc-classifications-normalized.csv"
      @call_number_ranges     = CSV.open(lc_classifications_file, headers: true).map {|row| row.to_h}
      @normalized_subjects    = CSV.open(lc_normalizations_file, headers: true).map do |row|
        key = row["Code"] + row["Range Start"] + "::" + row["Code"] + row["Range End"]
        [key, {normalized: row["Normalized Subject"], lj_subject: row["LJ Subject"]}]
      end.to_h
      @lc_class_pks           = Hash.new
    end


    def generate_table_files
      @journal_counter             = 0
      @publication_summary_counter = 0
      @use_summary_counter         = 0
      @citation_summary_counter    = 0
      @lc_classification_counter   = 0
      @grant_counter               = 0
      @agency_counter              = 0

      DataStream::Reader.new(@journalid_index, id_format: :string).each do |work_id, records|
        wos_titles = records.select {|r| r["type"] == "WebOfScienceTitle"}
        next unless wos_title_data_valid?(wos_titles)

        @journal_counter += 1
        title            = wos_titles.first
        bibs             = records.select {|r| r["type"] == "BibRecord"}
        pub_summaries    = records.select {|r| r["type"] == "PubSummary"}
        use_summaries    = records.select {|r| r["type"] == "UseSummary"}
        grants           = records.select {|r| r["type"] == "GrantRecord"}
        all_citing_recs  = records.select {|r| r["type"] == "CitingDocument"}
        citing_recs      = all_citing_recs.size == 0 ? [] : deduplicate_citing_documents(all_citing_recs)

        lc_classes   = bibs.map {|b| b["lc_classes"]}.flatten.compact.uniq
        publisher_id = @lookup_tables["publishers"][title["publisher"]]

        @tables["journals"] << [
          @journal_counter,
          title["title"],
          title["issn"],
          title["eissn"],
          lc_classes.join("; "),
          publisher_id
        ]

        process_categories_collections(title)
        process_summary_data(pub_summaries, use_summaries, citing_recs)
        process_lc_classifications(lc_classes)
        process_grants(grants)
      end
    end


    def setup_grants_tables
      @agencies = Hash.new do |hash, agency_name|
        @agency_counter += 1
        @tables["agencies"] << [@agency_counter, agency_name]
        hash[agency_name] = @agency_counter
      end
    end


    def process_grants(grants)
      grants.each do |grant|
        @grant_counter += 1
        @tables["grants"] << [@grant_counter, grant["ids"].join("; "), grant["institution"], grant["agency"]]
        grant["pref_agency_names"].each {|name| @tables["agencies_grants"] << [@agencies[name], @grant_counter]}
        @tables["grants_journals"] << [@grant_counter, @journal_counter]
      end
    end


    def process_lc_classifications(lc_classes)
      find_or_create_lc_classifications(lc_classes).each do |lc_classification_id|
        @tables["journals_lc_classifications"] << [@journal_counter, lc_classification_id]
      end
    end


    def find_or_create_lc_classifications(lc_classes)
      lc_classes.reduce(Array.new) do |matches, classification|
        lc_pattern_data = classification.match(/^([A-Z]+)([0-9]+\.{0,1}[0-9]+).*/)
        return matches unless lc_pattern_data

        # Using the parsed subclass and numeric component, collect each against the configured call number ranges
        subclass, number = lc_pattern_data.captures
        @call_number_ranges.select {|range| range["Classification Code"] == subclass}.each do |sub_range|
          if number.to_f.between?(sub_range["Start Range Number"].to_f, sub_range["End Range Number"].to_f)
            key         = sub_range["Start Range"] + "::" + sub_range["End Range"]
            lc_class_pk = @lc_class_pks[key].nil? ? create_lc_classification(sub_range) : @lc_class_pks[key]
            matches    << lc_class_pk
          end
        end
        matches
      end
    end


    def create_lc_classification(data)
      # First, add an entry to the serialized table
      @lc_classification_counter += 1
      lookup_key = data["Start Range"] + "::" + data["End Range"]
      normalized = @normalized_subjects[lookup_key]

      @tables["lc_classifications"] << [
        @lc_classification_counter,
        normalized[:normalized],
        normalized[:lj_subject],
        @top_classificaitons[data["Classification Code"][0]],
        data["Classification Code"],
        data["Start Range Number"],
        data["End Range Number"],
        data["Group1"],
        data["Group2"],
        data["Group3"],
        data["Group4"],
        data["Group5"]
      ]

      # Second, add the entry to the in-memory lookup table so a duplicate is not created
      @lc_class_pks[lookup_key] = @lc_classification_counter

      # Finally, return the PK
      @lc_classification_counter
    end


    def process_summary_data(pub_summaries, use_summaries, citing_recs)
      monthly_data = merge_inst_data(pub_summaries, use_summaries, citing_recs)
      monthly_data.each do |year, months|
        months.each do |month, data|
          date = "#{year}-#{month.to_s.rjust(2, "0")}-01"
          data.each do |inst, statistics|
            if statistics[:articles] > 0
              @publication_summary_counter += 1
              @tables["publication_summaries"] << [
                @publication_summary_counter, @journal_counter, date, inst.to_s,
                statistics[:articles].to_f.to_s, statistics[:with_grants].to_f.to_s
              ]
            end

            if statistics[:uses] > 0
              @use_summary_counter += 1
              @tables["use_summaries"] << [
                @use_summary_counter, @journal_counter, date, inst.to_s, statistics[:uses].to_f.to_s
              ]
            end

            if statistics[:cites] > 0
              @citation_summary_counter += 1
              @tables["citation_summaries"] << [
                @citation_summary_counter, @journal_counter, date, inst.to_s, statistics[:cites].to_f.to_s
              ]
            end
          end
        end
      end
    end


    def process_categories_collections(wos_title)
      @lookup_tables.keys.each do |field|
        next if field == "publishers"
        wos_title[field].each do |value|
          field_id = @lookup_tables[field][value]
          @tables["#{field}_journals"] << [field_id, @journal_counter]
        end
      end
    end


    def wos_title_data_valid?(wos_titles)
      wos_titles = Encomium.consolidate_wos_records(wos_titles) if wos_titles.size > 1
      if wos_titles.size > 1
        puts "WARNING: multiple WOS Titles Merged by ISSN"
        wos_titles.each do |r|
          print r["title"] + " " + r["publisher"] + " " + r["issn"] + " "
          print r["eissn"] + " " if r["eissn"]
          print r["collections"].join("; ")
          puts
        end
        false
      else
        true
      end
    end


    def setup_lookup_tables
      @lookup_counters = { "categories" => 0, "collections" => 0, "publishers" => 0 }

      @lookup_tables = @lookup_counters.keys.reduce(Hash.new) do |lookup_tables, table_name|
        lookup_tables[table_name] = Hash.new do |hash, name|
          @lookup_counters[table_name] += 1
          @tables[table_name] << [@lookup_counters[table_name], name]
          hash[name] = @lookup_counters[table_name]
        end
        lookup_tables
      end
    end


    def open_table_files
      options = {col_sep: "\t", quote_char: "", write_headers: true}
      @tables = TABLES.reduce(Hash.new) do |tables, config|
        name              = config[0]
        options[:headers] = config[1]
        tables[name]      = CSV.open(@output_dir + "/#{name}.tsv", "w+", **options)
        tables
      end
    end


    def close_table_files
      @tables.values.each {|file| file.close}
    end


    def process_journals
      DataStream::Reader.new(@journalid_index, id_format: :string).each do |work_id, records|
        wos_titles = records.select {|r| r["type"] == "WebOfScienceTitle"}
        next unless wos_title_data_valid?(wos_titles)

        bibs            = records.select {|r| r["type"] == "BibRecord"}
        pub_summaries   = records.select {|r| r["type"] == "PubSummary"}
        use_summaries   = records.select {|r| r["type"] == "UseSummary"}
        publisher_recs  = records.select {|r| r["type"] == "UsePublisherRecord"}
        all_citing_recs = records.select {|r| r["type"] == "CitingDocument"}
        citing_recs     = all_citing_recs.size == 0 ? [] : deduplicate_citing_documents(all_citing_recs)

        wos_title = wos_titles.first
        cats = wos_title["categories"].join("; ")
        cols = wos_title["collections"].join("; ")
        row = [wos_title["title"], wos_title["issn"], wos_title["eissn"], wos_title["publisher"], cats, cols]

        row << bibs.size
        row << bibs.map {|b| b["title"]}.uniq.join("; ")
        row << bibs.map {|b| b["lc_classes"]}.flatten.compact.uniq.join("; ")
        row << bibs.map {|b| b["issns"]}.flatten.uniq.join("; ")
        row << bibs.map {|b| b["oclc_numbers"]}.flatten.compact.uniq.join("; ")

        row << publisher_recs.reduce(Set.new) {|pubs, rec| pubs += rec["publishers"].split("; ")}.to_a.join("; ")

        uses  = use_summaries.reduce(Hash.new(0)) {|uses, s| uses[s["institution"]] += s["uses"]; uses}
        pubs  = pub_summaries.reduce(Hash.new(0)) {|pubs, s| pubs[s["institution"]] += s["articles"]; pubs}
        cites = citing_recs.reduce(Hash.new(0))   {|cites, c| cites[c["citing_inst"]] += 1; cites}

        summary_row = row + [
          pubs["mn"],  cites["mn"],  uses["mn"],
          pubs["osu"], cites["osu"], uses["osu"],
          pubs["uw"],  cites["uw"],  uses["uw"]
        ]
        @summary_csv << summary_row

        # Change the method name to merge_inst_data
        monthly_data = merge_inst_data(pub_summaries, use_summaries, citing_recs)
        monthly_data.each do |year, months|
          months.each do |month, data|
            monthly_row = row + ["#{year}-#{month.to_s.rjust(2, "0")}-01"]
            INSTITUTIONS.each do |inst|
              monthly_row << (data[inst].nil? ? 0 : data[inst][:articles])
              monthly_row << (data[inst].nil? ? 0 : data[inst][:cites])
              monthly_row << (data[inst].nil? ? 0 : data[inst][:uses])
            end
            @monthly_csv << monthly_row
          end
        end
      end
    end


    def deduplicate_citing_documents(citing_recs)
      begin
        citation_clusters = citing_recs.reduce(Hash.new) do |citation_clusters, citing_rec|
          citation_clusters[citing_rec["citation_id"]] = Set.new unless citation_clusters[citing_rec["citation_id"]]
          citation_clusters[citing_rec["citation_id"]] << citing_rec
          citation_clusters
        end
      rescue Exception => e
        puts
        puts citing_recs.inspect
        puts
        raise e
      end

      citation_clusters.values.map {|set| set.to_a}.flatten
    end

    def data_template
      Hash.new do |years, year|
        years[year] = Hash.new do |months, month|
          months[month] = Hash.new do |institutions, institution|
            institutions[institution] = {uses: 0.0, articles: 0.0, with_grants: 0.0, cites: 0.0}
          end
        end
      end
    end


    def merge_inst_data(pub_summaries, use_summaries, citing_recs)
      monthly_data = data_template
      monthly_data = merge_data_point(monthly_data, pub_summaries, "articles")
      monthly_data = merge_data_point(monthly_data, pub_summaries, "with_grants")
      monthly_data = merge_data_point(monthly_data, use_summaries, "uses")
      monthly_data = merge_data_point(monthly_data, citing_recs, "cites")
      monthly_data
    end


    def merge_data_point(monthly_data, summaries, data_point)
      begin
        summaries.each do |summary|
          date = Date.parse(summary["date"])
          if data_point == "cites"
            inst = summary["citing_inst"]
            measure = 1
          else
            inst = summary["institution"]
            measure = summary[data_point]
          end
          monthly_data[date.year][date.month][inst.to_sym][data_point.to_sym] += measure
        end
        monthly_data
      rescue Exception => e
        puts
        puts data_point.inspect
        puts summaries.inspect
        puts
        raise e
      end
    end


    def summary_headers
      Encomium::DataSet::BASE_FIELDS + Encomium::DataSet::INST_FIELDS
    end


    def monthly_headers
      Encomium::DataSet::BASE_FIELDS + ["Date"] + Encomium::DataSet::INST_FIELDS
    end


    BASE_FIELDS = [
      "WOS Title", "WOS ISSN", "WOS eISSN", "WOS Publisher", "WOS Categories", "WOS Collections",
      "MARC Cluster Size", "MARC Title Matches", "MARC LC Classes", "MARC ISSNs", "MARC OCLC Numbers",
      "COUNTER Publisher Matches"
    ]


    # TODO: make this part of a configuration
    INST_FIELDS = [
      "MN Articles",  "MN Cites",  "MN Uses",
      "OSU Articles", "OSU Cites", "OSU Uses",
      "UW Articles",  "UW Cites",  "UW Uses"
    ]


  end
end
