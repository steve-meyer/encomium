# frozen_string_literal: true

require "yaml"
require "bundler/setup"
require "encomium"


CONFIG   = YAML.load_file("config/files.yml")
base_dir = CONFIG["base_data_directory"]

# Outputs
wostitles_idx = base_dir + "/output/issn-indexed-wostitles.tsv"
bibtitles_idx = base_dir + "/output/issn-indexed-bib-records.tsv"

# Inputs
wostitle_csv = FileList[base_dir + "/wos-journals/*.csv"].each {|csv_file| file wostitles_idx => csv_file}
marc_files   = FileList[base_dir + "/MARC/*.mrc"].each         {|marc_file| file bibtitles_idx => marc_file}

task :build => [wostitles_idx, bibtitles_idx]


file bibtitles_idx do
  puts "Indexing MARC Records by ISSN"
  File.open(bibtitles_idx, "w+") do |output_file|
    marc_files.each do |marc_file|
      MARC::Reader.new(marc_file).each do |record|
        bib_record = Encomium::BibRecord.new(record)
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
