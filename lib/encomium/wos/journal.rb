module Encomium
  module WOS
    class Journal

      attr_reader :id, :title, :issn, :eissn, :publisher, :categories, :collections, :type

      def initialize(data, journal_list = nil)
        @journal_list = journal_list
        parse(data)
      end


      def to_json
        self.instance_variables.select {|var| var != :@journal_list}
            .reduce(Hash.new) {|h, var| h[var.to_s[1..-1]] = self.instance_variable_get(var); h}
            .to_json
      end


      def issns
        [self.issn, self.eissn].compact
      end


      def self.reindex_by_id(input_filepath, output_filepath)
        File.open(output_filepath, "w+") do |output_file|
          DataStream::Reader.new(input_filepath, id_format: :string).each do |issn, records|
            wos_titles    = records.select {|r| r["type"] == "WebOfScienceTitle"}
            next if wos_titles.size == 0

            wos_titles    = Encomium.consolidate_wos_records(wos_titles) if wos_titles.size > 1
            wos_title_ids = wos_titles.map {|t| t["id"]}.uniq
            wos_title_id  = wos_title_ids.first
            records.each {|r| output_file.puts([wos_title_id, r.to_json].join("\t"))}
          end
        end
      end


      private


      def parse(data)
        @id = @journal_list.counter
        @title = data["Journal title"]
        @issn = data["ISSN"]
        @eissn = data["eISSN"] == "" ? nil : data["eISSN"]
        @publisher = data["Publisher name"]
        @categories = data["Web of Science Categories"].split(" | ")
        @collections = data["Collection"]
        @type = "WebOfScienceTitle"
      end

    end
  end
end
