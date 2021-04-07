RSpec.describe Encomium::WOS::Journal do
  context "when loading WOS journals from a single file" do
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

    it "has collections" do
      expect(@first.collections).to eq(["AHCI"])
    end

    it "has a type" do
      expect(@first.type).to eq("WebOfScienceTitle")
    end

    it "can serialize itself as JSON" do
      expected = {
        id: 1, title: "AAA-ARBEITEN AUS ANGLISTIK UND AMERIKANISTIK", issn: "0171-5410", eissn: nil,
        publisher: "GUNTER NARR VERLAG", categories: ["Literature", "Language & Linguistics"], collections: ["AHCI"],
        type: "WebOfScienceTitle"
      }.to_json
      expect(@first.to_json).to eq(expected)
    end
  end

  context "when loading WOS journals from an Array of files" do
    before(:all) do
      csv_dir  = File.expand_path(File.dirname(__FILE__) + "/support/wos-journals-multiple")
      csv_data = Dir[csv_dir + "/*.csv"]
      journals = Encomium::WOS::JournalList.new(csv_data).reduce([]) {|journals, title| journals << title}
      @first   = journals.first
      @last    = journals.last
    end

    it "does not reset the journal counter from one file to the next" do
      expect(@first.id).to eq(1)
      expect(@last.id).to eq(4)
    end
  end

  context "when reindexing an ISSN file by WOS ID" do
    before(:all) do
      data_dir = File.expand_path(File.dirname(__FILE__) + "/support/issn-index")
      issn_idx = data_dir + "/issn-indexed-data.tsv"
      @jrnl_idx = data_dir + "/journalid-indexed-data.tsv"
      Encomium::WOS::Journal.reindex_by_id(issn_idx, @jrnl_idx)
      @journal_data = Hash.new {|h, wos_id| h[wos_id] = Array.new}
      DataStream::Reader.new(@jrnl_idx, id_format: :string).each do |wos_id, records|
        records.each {|rec| @journal_data[wos_id] << rec}
      end
    end

    after(:all) do
      FileUtils.rm(@jrnl_idx)
    end

    it "gathers all records associated with the same WOS title" do
      expect(@journal_data["55"].size).to eq(22)
    end

    it "finds all COUNTER use summary records" do
      use_summaries = get_journal_records(@journal_data, "UseSummary")
      expect(use_summaries.size).to eq(5)
    end

    it "finds all WOS titles sharing the same ID" do
      wos_titles = get_journal_records(@journal_data, "WebOfScienceTitle")
      expect(wos_titles.size).to eq(4)
    end

    it "ignores records that don't have a WOS title record" do
      bib_records = @journal_data.values.flatten.select {|r| r["type"] == "BibRecord"}
      non_indexed_bib = bib_records.select {|bib| bib["title"] == "Magazines for libraries"}
      expect(non_indexed_bib).to eq([])
    end
  end
end
