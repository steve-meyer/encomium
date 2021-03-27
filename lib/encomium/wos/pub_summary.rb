module Encomium
  module WOS
    class PubSummary

      attr_reader :journals, :article_count

      def initialize(article_files)
        @article_files = article_files
        @journals = Hash.new {|h, issn| h[issn] = date_template}
        @article_count = 0
      end


      def run
        @article_files.sort.each do |article_file|
          inst = File.basename( File.dirname(article_file) ).to_sym
          File.open(article_file).each do |line|
            @article_count += 1
            article = JSON.parse(line)
            issns = article["identifiers"].select {|id| id["type"] == "issn" || id["type"] == "eissn"}
                                          .map    {|id| id["value"]}
                                          .uniq

            next if issns.size == 0 || article["pub_year"].to_i > 2017

            issn_percentage = 1.0 / issns.size.to_f
            year  = article["pub_year"].to_i
            month = article["pub_month"].nil? ? 1 : MONTH_ABBRS.index(article["pub_month"][0..2])
            month = 1 if month.nil?

            issns.each do |issn|
              if Encomium.valid_issn?(issn)
                @journals[issn][year][month][inst][:articles]    += issn_percentage
                has_grants = article["grants"] && article["grants"].size > 0
                @journals[issn][year][month][inst][:with_grants] += issn_percentage if has_grants
              end
            end
          end
        end
      end


      private


      def date_template
        YEARS.map {|year| [year, (1..12).map {|i| [i, INSTITUTIONS.map {|inst| [inst, {articles: 0.0, with_grants: 0.0}]}.to_h]}.to_h]}.to_h
      end

    end
  end
end
