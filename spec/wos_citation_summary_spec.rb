RSpec.describe Encomium::WOS::CitationSummary do
  before(:all) do
    base_directory    = File.expand_path(File.dirname(__FILE__)) + "/support"
    @output_directory = base_directory + "/output"
    FileUtils.mkdir_p(@output_directory)

    article_data_dir       = base_directory + "/wos-articles"
    article_files          = Dir[article_data_dir + "/**/*.json"]
    cited_article_data_dir = base_directory + "/wos-cited-articles"
    cited_article_files    = Dir[cited_article_data_dir + "/*.json"]

    @citation_summary = Encomium::WOS::CitationSummary.new(article_files, cited_article_files, @output_directory)
    @citation_summary.run
  end

  after(:all) do
    FileUtils.rm_rf(@output_directory)
  end

  it "knows the number of articles it parses" do
    expect(@citation_summary.article_count).to eq(2)
  end

  it "knows the number of cited articles it parses" do
    expect(@citation_summary.cited_article_count).to eq(2)
  end

  context "the output file" do
    before(:all) do
      lines = File.open(Dir[@output_directory + "/*.tsv"].first).readlines
      @issns = lines.map {|line| line.split("\t").first}
      @citing_docs = lines.map {|line| JSON.parse(line.split("\t").last)}
    end

    it "has citations indexed by ISSN" do
      expect(@issns).to eq(["2469-9985", "2469-9993", "0094-0496"])
    end

    it "has multiple citing docs for the same cited article when the citing doc has multiple ISSNs" do
      expect(@citing_docs.map {|d| d["citation_id"]}).to eq([1, 1, 31])
    end
  end
end
