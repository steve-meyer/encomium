RSpec.describe Encomium::WOS::PubSummary do
  before(:all) do
    article_data_dir = File.expand_path(File.dirname(__FILE__) + "/support/wos-articles")
    article_files    = Dir[article_data_dir + "/**/*.json"]
    @pub_summary     = Encomium::WOS::PubSummary.new(article_files)
    @pub_summary.run
  end

  it "knows the number of articles it parses" do
    expect(@pub_summary.article_count).to eq(2)
  end

  it "splits authorship counts across ISSNs" do
    expect(@pub_summary.journals["1089-490X"][2015][10][:mn][:articles]).to eq(0.5)
    expect(@pub_summary.journals["0556-2813"][2015][10][:mn][:articles]).to eq(0.5)
  end

  it "counts authorships with grants (and splits across ISSNs)" do
    expect(@pub_summary.journals["1089-490X"][2015][10][:mn][:with_grants]).to eq(0.5)
    expect(@pub_summary.journals["0556-2813"][2015][10][:mn][:with_grants]).to eq(0.5)
  end

  it "sets the pub month to January when it is missing" do
    expect(@pub_summary.journals["0361-7882"][2015][01][:uw][:articles]).to eq(1.0)
  end

  it "sets the grants count to 0 when there is no grant data for an article" do
    expect(@pub_summary.journals["0361-7882"][2015][01][:uw][:with_grants]).to eq(0.0)
  end
end
