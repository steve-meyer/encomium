RSpec.describe Encomium::BibRecord do
  context("when loading bibliographic data from a MARC file") do
    before(:all) do
      marc_file  = File.expand_path(File.dirname(__FILE__) + "/support/sample.mrc")
      marc_record = MARC::Record.new_from_marc( File.read(marc_file) )
      @bib_record = Encomium::BibRecord.new(marc_record)
    end

    it "has a title" do
      expect(@bib_record.title).to eq("The Columbian phenix and Boston review")
    end

    it "has issns" do
      expect(@bib_record.issns).to eq(["2158-6322"])
    end

    it "has OCLC numbers" do
      expect(@bib_record.oclc_numbers).to eq([1564270, 3681200, 50677725, 564111688])
    end

    it "has LC classes" do
      expect(@bib_record.lc_classes).to eq(["AP2.A2"])
    end

    it "can serialize itself as JSON" do
      expected = {
        title: "The Columbian phenix and Boston review", issns: ["2158-6322"],
        oclc_numbers: [1564270, 3681200, 50677725, 564111688], lc_classes: ["AP2.A2"]
      }.to_json
      expect(@bib_record.to_json).to eq(expected)
    end
  end
end
