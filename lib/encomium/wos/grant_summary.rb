module Encomium
  module WOS
    class GrantSummary

      attr_reader :article_count

      def initialize(article_files, output_directory)
        @article_files = article_files
        @output_file   = output_directory + "/issn-indexed-grants.tsv"
        FileUtils.mkdir_p(output_directory)

        @article_count = 0
      end


      def run
        load_grant_agency_data
        File.open(@output_file, "w+") do |output_file|
          @article_files.sort.each do |article_file|
            inst = File.basename( File.dirname(article_file) ).to_sym
            File.open(article_file).each do |line|
              @article_count += 1
              article = JSON.parse(line)

              grants = parse_grants(article)
              grants = add_fed_reporter_name(grants)
              issns  = article["identifiers"].select {|id| id["type"] == "issn" || id["type"] == "eissn"}
                                             .map    {|id| id["value"]}
                                             .uniq

              next if grants.size == 0 || issns.size == 0 || article["pub_year"].to_i > 2017

              issns.each do |issn|
                grants.each do |grant|
                  grant["institution"] = inst
                  grant["type"] = "GrantRecord"
                  output_file.puts([issn, grant.to_json].join("\t"))
                end # grants.each do |grant|
              end # issns.each do |issn|
            end # File.open(article_file).each do |line|
          end # @article_files.sort.each do |article_file|
        end # File.open(@output_file, "w+") do |output_file|
      end


      protected


      def add_fed_reporter_name(grants)
        grants.each do |grant|
          agency_names = [grant["agency"]] + grant["pref_agency_names"]
          grant["fed_reporter_agency_name"] = agency_names.compact.map do |name|
            @grant_agencies.map {|pattern, label| label if name =~ pattern}.compact
          end.flatten.first
        end
        grants
      end


      def load_grant_agency_data
        grant_agencies_file = File.join(Encomium.config_dir, "/grant_agencies.yml")
        @grant_agencies = YAML.load_file(grant_agencies_file).reduce(Hash.new) do |agencies, agency_data|
          agency_data.last["matches"].each do |label_match|
            agencies[Regexp.new(label_match)] = agency_data.last["preferred_label"]
          end
          agencies
        end
      end


      # All the way upstream in the source XML (and therefore derivative JSON data) are entries like the following:
      #
      # <grant>
      #   <grant_agency>NIH Roadmap for Medical Research</grant_agency>
      #   <grant_agency pref="Y">United States Department of Health &amp; Human Services</grant_agency>
      #   <grant_agency pref="Y">National Institutes of Health (NIH) - USA</grant_agency>
      #   <grant_ids count="10">
      #     <grant_id>&lt;/bold&gt;</grant_id>
      #     <grant_id>U01 AR45580</grant_id>
      #     <grant_id>U01 AR45614</grant_id>
      #     <grant_id>U01 AR45632</grant_id>
      #     <grant_id>U01 AR45647</grant_id>
      #     <grant_id>U01 AR45654</grant_id>
      #     <grant_id>U01 AR45583</grant_id>
      #     <grant_id>U01 AG18197</grant_id>
      #     <grant_id>U01-AG027810</grant_id>
      #     <grant_id>UL1 RR024140&lt;bold&gt;</grant_id>
      #   </grant_ids>
      # </grant>
      #
      # This method will remove the junk HTML element strings <bold> and </bold> and then select
      # only the remaining grants with non-empty string IDs.
      def parse_grants(article)
        if article["grants"].nil?
          Array.new
        else
          # First fix the grant IDs that contain an HTML <bold> element.
          # * Strip the strings '<bold>' and '</bold>' out of the grant IDs
          # * Delete any grant IDs that are result in empty strings
          grants = article["grants"].map do |grant|
            grant["ids"] = grant["ids"].map {|id| id.gsub(/<\/{0,1}bold>/, "").strip}.delete_if {|id| id == ""} if grant["ids"]
            grant
          end

          # Then select only the grants that still have IDs
          grants.select {|grant| !grant["ids"].nil? && grant["ids"].size > 0}
        end
      end

    end
  end
end
