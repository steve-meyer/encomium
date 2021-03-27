RSpec.describe Encomium::COUNTER::UseSummary do
  before(:all) do
    counter_data_dir = File.expand_path(File.dirname(__FILE__) + "/support/counter")
    counter_files    = Dir[counter_data_dir + "/**/*.csv"]
    @use_summary     = Encomium::COUNTER::UseSummary.new(counter_files)
    @use_summary.run
  end

  it "knows the number of COUNTER titles it parses" do
    expect(@use_summary.title_count).to eq(2)
  end

  it "has journal entries for valid ISSNs" do
    expect(@use_summary.journals["2168-4081"]).not_to be nil
  end

  it "has a publisher for a journal" do
    expect(@use_summary.journals["2168-4081"][:publishers].to_a).to eq(["ACM"])
  end

  it "records uses by date" do
    expect(@use_summary.journals["2168-4081"][:uses][2017][1][:uw]).to eq(811)
  end

  it "has journal entries for valid ISSNs" do
    # Note that asking for the entry will create a stub since default Hash pattern is used.
    expect(@use_summary.journals.has_key?("-")).to be false
  end
end
