# frozen_string_literal: true

require "encomium"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end


def get_journal_records(journal_data, type)
  journal_data["55"].select {|r| r["type"] == type}
end


def table_data(name)
  data_dir = File.expand_path(File.dirname(__FILE__) + "/support/database")
  CSV.open("#{data_dir}/#{name}.tsv", headers: true, col_sep: "\t", quote_char: nil).map {|row| row.to_h}
end


def get_bib_record(filename)
  marc_file  = File.expand_path(File.dirname(__FILE__) + "/support/marc/" + filename)
  marc_record = MARC::Record.new_from_marc( File.read(marc_file) )
  Encomium::MARC::BibRecord.new(marc_record)
end
