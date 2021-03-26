RSpec.describe Encomium::WOS::Journal do
  context("when loading WOS journals from a single file") do
    before(:all) do
      csv_data = File.expand_path(File.dirname(__FILE__) + "/support/wos-journals-single/wos-core_AHCI.csv")
      journals = Encomium::WOS::JournalList.new(csv_data).reduce([]) {|journals, title| journals << title}
      @first   = journals.first
      @last    = journals.last
    end

    it "has an id assigned" do
      expect(@first.id).to eq(1)
      expect(@last.id).to eq(2)
    end

    it "has a title" do
      expect(@first.title).to eq("AAA-ARBEITEN AUS ANGLISTIK UND AMERIKANISTIK")
    end

    it "has an ISSN" do
      expect(@first.issn).to eq("0171-5410")
    end

    it "has an eISSN" do
      expect(@first.eissn).to be nil
    end

    it "can produce a compacted list of both ISSNs" do
      expect(@first.issns).to eq(["0171-5410"])
    end

    it "has a publisher" do
      expect(@first.publisher).to eq("GUNTER NARR VERLAG")
    end

    it "has categories" do
      expect(@first.categories).to eq(["Literature", "Language & Linguistics"])
    end

    it "has a collection" do
      expect(@first.collection).to eq("AHCI")
    end

    it "has a type" do
      expect(@first.type).to eq("WebOfScienceTitle")
    end

    it "can serialize itself as JSON" do
      expected = {
        id: 1, title: "AAA-ARBEITEN AUS ANGLISTIK UND AMERIKANISTIK", issn: "0171-5410", eissn: nil,
        publisher: "GUNTER NARR VERLAG", categories: ["Literature", "Language & Linguistics"], collection: "AHCI",
        type: "WebOfScienceTitle"
      }.to_json
      expect(@first.to_json).to eq(expected)
    end
  end

  context("when loading WOS journals from a directory of files") do
    before(:all) do
      csv_data = File.expand_path(File.dirname(__FILE__) + "/support/wos-journals-multiple")
      journals = Encomium::WOS::JournalList.new(csv_data).reduce([]) {|journals, title| journals << title}
      @first   = journals.first
      @last    = journals.last
    end

    it "does not reset the journal counter from one file to the next" do
      expect(@first.id).to eq(1)
      expect(@last.id).to eq(4)
    end
  end
end
