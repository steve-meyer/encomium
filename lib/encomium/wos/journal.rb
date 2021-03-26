module Encomium
  module WOS
    class Journal

      attr_reader :id, :title, :issn, :eissn, :publisher, :categories, :collection, :type

      def initialize(data, journal_list = nil)
        @journal_list = journal_list
        parse(data)
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
      end

    end
  end
end
