# frozen_string_literal: true

require "yaml"
require "bundler/setup"
require "encomium"


CONFIG     = YAML.load_file("config/files.yml")
base_dir   = CONFIG["base_data_directory"]
output_dir = base_dir + "/output"


# Outputs
wostitles_idx  = output_dir + "/issn-indexed-wostitles.tsv"
bibtitles_idx  = output_dir + "/issn-indexed-bib-records.tsv"
pubsummary_idx = output_dir + "/issn-indexed-publication-summaries.tsv"
citsummary_idx = output_dir + "/issn-indexed-citing-docs.tsv"
usesummary_idx = output_dir + "/issn-indexed-use-summaries.tsv"
issn_idx       = output_dir + "/issn-indexed-data.tsv"
journalid_idx  = output_dir + "/journalid-indexed-data.tsv"
summary_output = output_dir + "/combined-data-summary.csv"

# Inputs
wostitle_csv = FileList[base_dir + "/wos-journals/*.csv"].each {|csv_file|  file wostitles_idx => csv_file}
marc_files   = FileList[base_dir + "/MARC/*.mrc"].each         {|marc_file| file bibtitles_idx => marc_file}
use_data     = FileList[base_dir + "/COUNTER/**/*.csv"].each   {|use_file|  file usesummary_idx => use_file}
article_data = FileList[base_dir + "/articles/**/*.json"]
cited_docs   = FileList[base_dir + "/cited-articles/*.json"]
article_data.each                {|article_file| file pubsummary_idx => article_file}
(cited_docs + article_data).each {|article_file| file citsummary_idx => article_file}


task :build => [wostitles_idx, bibtitles_idx, pubsummary_idx, citsummary_idx, usesummary_idx, issn_idx, journalid_idx, summary_output]


file summary_output => journalid_idx do
  puts "Generating summary output"
  Encomium::DataSet.new(journalid_idx, output_dir).generate_analysis_csv
end


file journalid_idx => issn_idx do
  puts "Reindexing clustered ISSN data by WOS journal ID"
  Encomium::WOS::Journal.reindex_by_id(issn_idx, journalid_idx)
  FileUtils.cd(File.expand_path(File.dirname(__FILE__)) + "/lib") do
    `java -jar filesorter-0.1.0.jar #{journalid_idx}`
  end
end


file issn_idx => [wostitles_idx, bibtitles_idx, pubsummary_idx, citsummary_idx, usesummary_idx] do
  puts "Creating combined ISSN index file"
  `cat #{wostitles_idx} #{bibtitles_idx} #{pubsummary_idx} #{citsummary_idx} #{usesummary_idx} > #{issn_idx}`
  puts "Sorting ISSN index"
  FileUtils.cd(File.expand_path(File.dirname(__FILE__)) + "/lib") do
    `java -jar filesorter-0.1.0.jar #{issn_idx}`
  end
end



file usesummary_idx do
  puts "Indexing use data by ISSN"
  File.open(usesummary_idx, "w+") do |output_file|
    use_summary = Encomium::COUNTER::UseSummary.new(use_data)
    use_summary.run
    use_summary.journals.each do |issn, data|
      data[:uses].each do |year, months|
        months.each do |month, institutions|
          institutions.each do |code, use_count|
            if use_count > 0
              date   = "#{year}-#{month.to_s.rjust(2, "0")}-01"
              record = {institution: code, uses: use_count, date: date, type: "UseSummary"}
              output_file.puts([issn, record.to_json].join("\t"))
            end
          end
        end
      end
      publishers = data[:publishers].to_a.select {|pub| pub.to_s.strip != ""}.map {|pub| pub.to_s.strip}
      record = {publishers: publishers.to_a.join("; "), type: "UsePublisherRecord"}
      output_file.puts([issn, record.to_json].join("\t"))
    end
    if use_summary.bad_counter_rows.size > 0
      puts "Bad COUNTER rows by institution:"
      use_summary.bad_counter_rows.each do |inst, reasons|
        reasons.to_a.sort.each {|reason, count| puts "#{inst}: #{reason} (#{count})"}
      end
    end
  end
end


file citsummary_idx do
  puts "Indexing cited references by ISSN"
  citation_summary = Encomium::WOS::CitationSummary.new(article_data, cited_docs, output_dir)
  citation_summary.run
end


file pubsummary_idx do
  puts "Indexing articles by ISSN"
  File.open(pubsummary_idx, "w+") do |output_file|
    pub_summary = Encomium::WOS::PubSummary.new(article_data)
    pub_summary.run
    pub_summary.journals.each do |issn, data|
      data.each do |year, months|
        months.each do |month, institutions|
          institutions.each do |code, counts|
            if counts[:articles] > 0
              date   = "#{year}-#{month.to_s.rjust(2, "0")}-01"
              record = {
                institution: code, articles: counts[:articles], with_grants: counts[:with_grants],
                date: date, type: "PubSummary"
              }
              output_file.puts([issn, record.to_json].join("\t"))
            end
          end
        end
      end
    end
  end
end


file bibtitles_idx do
  puts "Indexing MARC Records by ISSN"
  File.open(bibtitles_idx, "w+") do |output_file|
    marc_files.each do |marc_file|
      MARC::Reader.new(marc_file).each do |record|
        bib_record = Encomium::MARC::BibRecord.new(record)
        bib_record.issns.each do |issn|
          output_file.puts([issn, bib_record.to_json].join("\t")) if Encomium.valid_issn?(issn)
        end
      end
    end
  end
end


file wostitles_idx do
  puts "Indexing WOS Title Lists by ISSN"
  File.open(wostitles_idx, "w+") do |output_file|
    Encomium::WOS::JournalList.new(wostitle_csv).each do |wos_journal|
      wos_journal.issns.each do |issn|
        output_file.puts([issn, wos_journal.to_json].join("\t")) if Encomium.valid_issn?(issn)
      end
    end
  end
end
