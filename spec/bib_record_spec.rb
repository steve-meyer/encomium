RSpec.describe Encomium::MARC::BibRecord do
  context "when loading bibliographic data from a MARC file" do
    before(:all) do
      marc_file  = File.expand_path(File.dirname(__FILE__) + "/support/marc/sample.mrc")
      marc_record = MARC::Record.new_from_marc( File.read(marc_file) )
      @bib_record = Encomium::MARC::BibRecord.new(marc_record)
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

    it "has LC classes that do not include cutter subdivisions" do
      expect(@bib_record.lc_classes).to eq(["AP2"])
    end

    it "has a type" do
      expect(@bib_record.type).to eq("BibRecord")
    end

    it "can serialize itself as JSON" do
      expected = {
        title: "The Columbian phenix and Boston review", issns: ["2158-6322"],
        oclc_numbers: [1564270, 3681200, 50677725, 564111688], lc_classes: ["AP2"],
        type: "BibRecord"
      }.to_json
      expect(@bib_record.to_json).to eq(expected)
    end
  end


  context "when parsing LC Class data" do
    it "should include the records valid LC Class from a record with bad data" do
      bib_record = get_bib_record("bad-lc-class.mrc")
      expect(bib_record.lc_classes).to include("AM1")
    end

    it "should not include an LC class for 'ISSN Record'" do
      bib_record = get_bib_record("bad-lc-class.mrc")
      expect(bib_record.lc_classes).not_to include("ISSN Record")
    end

    it "should ignore the case of a bad 'ISSN Record' LC Class" do
      bib_record = get_bib_record("bad-lc-class-uppercase.mrc")
      expect(bib_record.lc_classes).not_to include("ISSN RECORD")
    end

    it "should strip extraneous punctuation for assumed classes (i.e., chars '[' and ']')" do
      bib_record = get_bib_record("extra-punctuation.mrc")
      expect(bib_record.lc_classes).to eq(["RJ1"])
    end

    it "should not include acquisitions notes" do
      bib_record = get_bib_record("acq-note.mrc")
      expect(bib_record.lc_classes).to eq(["RJ1"])
    end

    it "should not include microfilm notes" do
      bib_record = get_bib_record("microfilm-note.mrc")
      expect(bib_record.lc_classes).to eq(["AP2"])
    end

    it "should parse the numeric part to the decimal level" do
      bib_record = get_bib_record("decimal-class-num.mrc")
      expect(bib_record.lc_classes).to eq(["B808.5"])
    end
  end
end
