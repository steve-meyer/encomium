module Encomium
  module WOS
    class Journal

      attr_reader :id, :title, :issn, :eissn, :publisher, :categories, :collection, :type

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


      private


      def parse(data)
        @id = @journal_list.counter
        @title = data["Journal title"]
        @issn = data["ISSN"]
        @eissn = data["eISSN"] == "" ? nil : data["eISSN"]
        @publisher = data["Publisher name"]
        @categories = data["Web of Science Categories"].split(" | ")
        @collection = data["Collection"]
        @type = "WebOfScienceTitle"
      end

    end
  end
end
