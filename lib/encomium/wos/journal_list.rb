module Encomium
  module WOS
    class JournalList

      include Enumerable

      def initialize(csv_data)
        @csv_data = Array.new
        csv_data.is_a?(Array) ? @csv_data += csv_data : @csv_data << csv_data
      end


      def counter
        @journal_counter = @journal_counter.nil? ? 1 : @journal_counter += 1
      end


      def each(&block)
        @csv_data.each do |csv_file|
          @collection = File.basename(csv_file, ".csv").gsub(/^wos[_-]/, "").gsub("core_", "")
          CSV.open(csv_file, headers: true).each do |row|
            row["Collection"] = @collection
            yield Encomium::WOS::Journal.new(row, self)
          end
        end
      end

    end
  end
end
