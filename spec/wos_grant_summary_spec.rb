RSpec.describe Encomium::WOS::GrantSummary do
  before(:all) do
    base_directory    = File.expand_path(File.dirname(__FILE__)) + "/support"
    @output_directory = base_directory + "/output"
    FileUtils.mkdir_p(@output_directory)

    article_data_dir  = base_directory + "/wos-articles"
    article_files     = Dir[article_data_dir + "/**/*.json"]
    @output_directory = base_directory + "/output"

    @grant_summary = Encomium::WOS::GrantSummary.new(article_files, @output_directory)
    @grant_summary.run
  end

  after(:all) do
    FileUtils.rm_rf(@output_directory)
  end

  it "knows the number of articles it parses" do
    expect(@grant_summary.article_count).to eq(2)
  end

  context "the grants" do
    before(:all) do
      lines = File.open(Dir[@output_directory + "/*.tsv"].first).readlines
      @issns = lines.map {|line| line.split("\t").first}
      @grants = lines.map {|line| JSON.parse(line.split("\t").last)}
    end

    it "indexes by ISSN" do
      expect(@issns).to eq(["0556-2813", "1089-490X"])
    end

    it "has the right number of grants" do
      expect(@grants.size).to eq(2)
    end

    it "parses the grant IDs" do
      expect(@grants.first["ids"]).to eq(["DE-FG02-87ER40328", "DE-FG02-03ER41259"])
    end
  end
end
