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
        File.open(@output_file, "w+") do |output_file|
          @article_files.sort.each do |article_file|
            inst = File.basename( File.dirname(article_file) ).to_sym
            File.open(article_file).each do |line|
              @article_count += 1
              article = JSON.parse(line)

              grants = article["grants"].nil? ? [] : article["grants"].select {|grant| !grant["ids"].nil? && grant["ids"].size > 0}
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

    end
  end
end
