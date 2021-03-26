# frozen_string_literal: true

require "yaml"
# require "bundler/gem_tasks"
# require "rspec/core/rake_task"
require "bundler/setup"
require "encomium"


CONFIG = YAML.load_file("config/files.yml")


task :wostitles_by_issn do
  puts "Indexing WOS Title Lists by ISSN"
  input_csv_data = CONFIG["base_data_directory"] + "/wos-journals"
  output_data    = CONFIG["base_data_directory"] + "/output/issn-indexed-data.tsv"

  File.open(output_data, "w+") do |output_file|
    Encomium::WOS::JournalList.new(input_csv_data).each do |wos_journal|
      wos_journal.issns.each do |issn|
        output_file.puts([issn, wos_journal.to_json].join("\t")) if Encomium.valid_issn?(issn)
      end
    end
  end
end
task wostitles_by_issn: [:setup_output_dir]


task :setup_output_dir do
  mkdir_p CONFIG["base_data_directory"] + "/output"
end
