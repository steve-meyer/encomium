# frozen_string_literal: true

RSpec.describe Encomium do
  it "has a version number" do
    expect(Encomium::VERSION).not_to be nil
  end

  context "when validating ISSNs" do
    it "considers 4 digits, dash, 4 digits valid" do
      expect(Encomium.valid_issn?("1234-5678")).to be true
    end

    it "considers a number to be invalid" do
      expect(Encomium.valid_issn?(12345678)).to be false
    end

    it "considers 4 digits, dash, uppercase X valid" do
      expect(Encomium.valid_issn?("1234-567X")).to be true
    end

    it "considers 4 digits, dash, lowercase x valid" do
      expect(Encomium.valid_issn?("1234-567x")).to be true
    end
  end
end
