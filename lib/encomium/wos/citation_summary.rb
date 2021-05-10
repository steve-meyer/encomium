module Encomium
  module WOS
    class CitationSummary

      attr_reader :article_count, :cited_article_count

      def initialize(article_files, cited_article_files, output_directory)
        @article_files       = article_files
        @cited_article_files = cited_article_files
        @output_directory    = output_directory
        @tmp_directory       = @output_directory + "/tmp"
        @article_count       = 0
        @cited_article_count = 0
      end


      def run
        FileUtils.mkdir_p(@tmp_directory)
        @article_id_index = @tmp_directory + "/wos-id-indexed-articles.tsv"
        index_articles_by_wosid
        index_cited_articles_by_wosid
        sort_wosid_file
        index_articles_by_issn
      end


      private


      def index_articles_by_issn
        issn_index = @output_directory + "/issn-indexed-citing-docs.tsv"
        File.open(issn_index, "w+") do |output_file|
          DataStream::Reader.new(@article_id_index, id_format: :string).each do |wos_id, records|
            cited_reference = records.select {|r| r["type"] == "CitedReference"}.first
            citing_articles = records.select {|r| r["type"] == "CitingDocument"}

            if cited_reference
              cited_issns = cited_reference["identifiers"].select {|id| id["type"] == "issn" || id["type"] == "eissn"}
                                                          .map    {|id| id["value"]}
              cited_issns.each do |issn|
                citing_articles.each do |citing_article|
                  output_file.puts([issn, citing_article.to_json].join("\t"))
                end
              end
            end
          end
        end
      end


      def sort_wosid_file
        FileUtils.cd(File.expand_path(File.dirname(__FILE__)) + "/../../") do
          `java -jar filesorter-0.1.0.jar #{@article_id_index}`
        end
      end


      def index_cited_articles_by_wosid
        File.open(@article_id_index, "a+") do |output_file|
          @cited_article_files.sort.each do |article_file|
            File.open(article_file).each do |line|
              article = JSON.parse(line)
              @cited_article_count += 1
              record = {
                cited_article_id: article["id"], date: parse_date(article),
                type: "CitedReference", identifiers: article["identifiers"]
              }
              output_file.puts([article["id"], record.to_json].join("\t"))
            end
          end
        end
      end


      def index_articles_by_wosid
        File.open(@article_id_index, "w+") do |output_file|
          @article_files.sort.each do |article_file|
            institution = File.basename( File.dirname(article_file) )
            File.open(article_file).each do |line|
              article = JSON.parse(line)
              @article_count += 1

              if article["references"]
                article["references"].each do |reference|
                  if !reference["id"].nil? && reference["id"][0,4] == "WOS:" && !reference["id"].match('\.')
                    citation_id = counter
                    record = {
                      citation_id: citation_id, citing_article_id: article["id"],
                      date: parse_date(article), citing_inst: institution,
                      type: "CitingDocument", identifiers: article["identifiers"]
                    }
                    output_file.puts([reference["id"], record.to_json].join("\t"))
                  end
                end
              end
            end
          end
        end
      end


      def counter
        @citation_counter = @citation_counter.nil? ? 1 : @citation_counter += 1
      end


      def parse_date(article)
        year   = article["pub_year"].to_i
        month  = article["pub_month"].nil? ? 1 : MONTH_ABBRS.index(article["pub_month"][0..2])
        month  = 1 if month.nil?
        "#{year}-#{month.to_s.rjust(2, "0")}-01"
      end


    end
  end
end
