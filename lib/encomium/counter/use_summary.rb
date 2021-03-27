module Encomium
  module COUNTER
    class UseSummary

      attr_reader :title_count, :journals


      def initialize(counter_files)
        @counter_files = counter_files
        @title_count = 0
        @journals = Hash.new {|h, issn| h[issn] = data_template}
      end


      def run
        bad_counter_rows = Hash.new(0)
        @counter_files.sort.each do |use_file|
          institution = File.basename( File.dirname(use_file) )
          CSV.open(use_file, headers: true).each do |row|
            @title_count += 1

            issn = row["ISSN"]
            issn = row["eISSN"] unless Encomium.valid_issn?(issn)
            issn = row["Origin ISSN"] unless Encomium.valid_issn?(issn)
            issn = row["Origin EISSN"] unless Encomium.valid_issn?(issn)
            next unless Encomium.valid_issn?(issn) # or !is_valid_issn?(issn)

            begin
              uses = row["Uses (SUM)"]
              uses = row["JR1 - Journal Usage Counter (total)"] if uses.nil?
              publisher = row["Publisher"]
              date_raw = row["Date"]
              date_raw = row["Usage Date"] if date_raw.nil?
              date = parse_date(date_raw)

              @journals[issn][:uses][date.year][date.month][institution.to_sym] += uses.to_i
              @journals[issn][:publishers] << publisher
            rescue Exception => e
              puts e.message
              bad_counter_rows[institution] += 1
            end
          end
        end
      end


      private


      def data_template
        {
          publishers: Set.new,
          uses: YEARS.map {|year| [year, (1..12).map {|i| [i, INSTITUTIONS.map {|inst| [inst, 0]}.to_h]}.to_h]}.to_h
        }
      end



      def parse_date(date_str)
        case date_str
        when /\d{1,2}\/\d{1,2}\/\d{1,2}/ then Date.strptime(date_str, "%m/%d/%y")
        when /\d{4}\-\d{2}\-\d{2}/ then Date.parse(date_str)
        else raise Exception.new("Bad date: #{date_str}")
        end
      end


    end
  end
end
