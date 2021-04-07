module Encomium
  class DataSet


    def initialize(journalid_index, output_dir)
      @journalid_index = journalid_index
      @output_dir = output_dir
      @summary_output = output_dir + "/combined-data-summary.csv"
      @monthly_output = output_dir + "/combined-data-monthly.csv"
    end


    def generate_analysis_csv
      @summary_csv = CSV.open(@summary_output, "w+", headers: summary_headers, write_headers: true)
      @monthly_csv = CSV.open(@monthly_output, "w+", headers: monthly_headers, write_headers: true)

      process_journals

      @summary_csv.close
      @monthly_csv.close
    end


    private


    def process_journals
      DataStream::Reader.new(@journalid_index, id_format: :string).each do |work_id, records|
        skip = false
        wos_titles      = records.select {|r| r["type"] == "WebOfScienceTitle"}
        bibs            = records.select {|r| r["type"] == "BibRecord"}
        pub_summaries   = records.select {|r| r["type"] == "PubSummary"}
        use_summaries   = records.select {|r| r["type"] == "UseSummary"}
        publisher_recs  = records.select {|r| r["type"] == "UsePublisherRecord"}
        all_citing_recs = records.select {|r| r["type"] == "CitingDocument"}
        citing_recs     = all_citing_recs.size == 0 ? [] : deduplicate_citing_documents(all_citing_recs)

        wos_titles = Encomium.consolidate_wos_records(wos_titles) if wos_titles.size > 1
        if wos_titles.size > 1
          skip = true
          puts "WARNING: multiple WOS Titles Merged by ISSN"
          wos_titles.each do |r|
            print r["title"] + " " + r["publisher"] + " " + r["issn"] + " "
            print r["eissn"] + " " if r["eissn"]
            print r["collection"].join("; ")
            puts
          end
        end
        next if skip

        wos_title = wos_titles.first
        cats = wos_title["categories"].join("; ")
        # TODO: make this always an Array
        cols = wos_title["collection"].is_a?(Array) ? wos_title["collection"].join("; ") : wos_title["collection"]
        row = [wos_title["title"], wos_title["issn"], wos_title["eissn"], wos_title["publisher"], cats, cols]

        row << bibs.size
        row << bibs.map {|b| b["title"]}.uniq.join("; ")
        row << bibs.map {|b| b["topClassifications"]}.flatten.compact.uniq.join("; ")
        row << bibs.map {|b| b["issns"]}.flatten.uniq.join("; ")

        row << bibs.map {|b| b["oclcNumbers"].nil? ? nil : b["oclcNumbers"].split("; ")}
                   .flatten
                   .compact
                   .uniq
                   .join("; ")

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
            institutions[institution] = {uses: 0.0, articles: 0.0, cites: 0.0}
          end
        end
      end
    end


    def merge_inst_data(pub_summaries, use_summaries, citing_recs)
      monthly_data = data_template
      monthly_data = merge_data_point(monthly_data, pub_summaries, "articles")
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
