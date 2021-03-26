# frozen_string_literal: true

require_relative "encomium/version"

module Encomium
  class Error < StandardError; end

  class << self
    def valid_issn?(issn)
      issn.is_a?(String) && (issn =~ /^[0-9]{4}-[0-9]{3}[0-9xX]$/) == 0
    end
  end
end
