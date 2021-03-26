# frozen_string_literal: true

require "yaml"
require "bundler/setup"
require "encomium"


CONFIG   = YAML.load_file("config/files.yml")
base_dir = CONFIG["base_data_directory"]

# Outputs
wostitles_idx = base_dir + "/output/issn-indexed-wostitles.tsv"

# Inputs
wostitle_csv = FileList[base_dir + "/wos-journals/*.csv"].each {|wostitle_csv| file wostitles_idx => wostitle_csv}


task :build => [wostitles_idx]


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
