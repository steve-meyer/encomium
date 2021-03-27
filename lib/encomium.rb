# frozen_string_literal: true

require "csv"
require "json"
require "fileutils"
require "marc"
require "data_stream"

require_relative "encomium/version"
require_relative "encomium/wos/journal_list"
require_relative "encomium/wos/journal"
require_relative "encomium/wos/pub_summary"
require_relative "encomium/wos/citation_summary"
require_relative "encomium/bib_record"


module Encomium
  class Error < StandardError; end

  # TODO: make this configurable
  YEARS        = [2015, 2016, 2017]
  INSTITUTIONS = [:mn, :osu, :uw]
  MONTH_ABBRS  = Date::MONTHNAMES.map {|name| name.nil? ? nil : name.upcase[0..2]}


  class << self

    def valid_issn?(issn)
      issn.is_a?(String) && (issn =~ /^[0-9]{4}-[0-9]{3}[0-9xX]$/) == 0
    end

  end
end
