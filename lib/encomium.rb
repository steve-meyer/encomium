# frozen_string_literal: true

require "csv"
require "json"
require "marc"

require_relative "encomium/version"
require_relative "encomium/wos/journal_list"
require_relative "encomium/wos/journal"
require_relative "encomium/bib_record"

module Encomium
  class Error < StandardError; end

  class << self

    def valid_issn?(issn)
      issn.is_a?(String) && (issn =~ /^[0-9]{4}-[0-9]{3}[0-9xX]$/) == 0
    end

  end
end
