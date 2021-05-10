# frozen_string_literal: true

require "csv"
require "json"
require "yaml"
require "fileutils"
require "marc"
require "data_stream"

require_relative "encomium/version"
require_relative "encomium/data_set"
require_relative "encomium/counter/use_summary"
require_relative "encomium/wos/journal_list"
require_relative "encomium/wos/journal"
require_relative "encomium/wos/pub_summary"
require_relative "encomium/wos/citation_summary"
require_relative "encomium/wos/grant_summary"
require_relative "encomium/marc/bib_record"


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


    def consolidate_wos_records(wos_titles)
      titles = wos_titles.reduce(Hash.new) do |titles, title|
        key = title["title"].to_s + "::" + title["issn"].to_s + "::" + title["eissn"].to_s
        if titles.has_key?(key)
          titles[key].merge!(title) {|k, old_v, new_v| old_v == new_v ? old_v : [old_v, new_v].flatten.compact.uniq}
        else
          titles[key] = title
        end
        titles
      end
      titles.values.map {|t| t["id"] = t["id"].sort.first if t["id"].is_a?(Array); t}
    end


  end
end
