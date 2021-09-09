RSpec.describe Encomium::DataSet do
  context "when generating database tables" do
    before(:all) do
      @data_dir      = File.expand_path(File.dirname(__FILE__) + "/support/database")
      journalid_idx  = @data_dir + "/journalid-indexed-data.tsv"
      Encomium::DataSet.new(journalid_idx, @data_dir).generate_tables
    end

    after(:all) do
      Encomium::DataSet::TABLES.keys.each {|table| FileUtils.rm(@data_dir + "/" + table + ".tsv")}
    end

    context "an entry in the journals table" do
      before(:all) do
        @journal_data = table_data("journals")
        @journal      = @journal_data.first
      end

      it "generates the correct number of journals" do
        expect(@journal_data.size).to eq(1)
      end

      it "has a primary key" do
        expect(@journal["id"]).to eq("1")
      end

      it "has a title" do
        expect(@journal["title"]).to eq("ADVANCES IN CONDENSED MATTER PHYSICS")
      end

      it "has an ISSN" do
        expect(@journal["issn"]).to eq("1687-8108")
      end

      it "has an eISSN" do
        expect(@journal["eissn"]).to eq("1687-8124")
      end

      it "has LC classes" do
        expect(@journal["lc_classes"]).to eq("QC173.45")
      end

      it "has a publisher ID" do
        expect(@journal["publisher_id"]).to eq("1")
      end
    end

    context "an entry in the LC classes table" do
      before(:all) do
        @lc_class_data = table_data("lc_classifications")
        @journals_lcclasses = table_data("journals_lc_classifications")
      end

      context "the LC classification" do
        before(:all) do
          @lc_class = @lc_class_data.first
        end

        it "has a code" do
          expect(@lc_class["code"]).to eq("QC")
        end

        it "has a start range number" do
          expect(@lc_class["range_start"]).to eq("170.0")
        end

        it "has an end range number" do
          expect(@lc_class["range_end"]).to eq("197.0")
        end

        it "has a top classification" do
          expect(@lc_class["section"]).to eq("Science")
        end

        it "has a normalized subject" do
          expect(@lc_class["normalized_subject"]).to eq("Physics (QC)")
        end

        it "has a Library Journal subject" do
          expect(@lc_class["lj_subject"]).to eq("Physics")
        end

        it "has a group 1 label" do
          expect(@lc_class["group_1"]).to eq("Physics")
        end

        it "has a group 2 label" do
          expect(@lc_class["group_2"]).to eq("Atomic physics. Constitution and properties of matter Including molecular physics, relativity, quantum theory, and solid state physics")
        end

        it "has a group 3 label" do
          expect(@lc_class["group_3"]).to be nil
        end

        it "has a group 4 label" do
          expect(@lc_class["group_4"]).to be nil
        end

        it "has a group 5 label" do
          expect(@lc_class["group_5"]).to be nil
        end
      end

      it "creates the journals/LC classes join table entry" do
        expect(@journals_lcclasses).to include({"journal_id" => "1", "lc_classification_id" => "1"})
      end
    end

    context "an entry in the categories table" do
      before(:all) do
        @categories_data    = table_data("categories")
        @cats_journals_data = table_data("categories_journals")
      end

      it "creates the correct number of categories by deduplicating repeating categories" do
        expect(@categories_data.size).to eq(3)
      end

      it "creates the categories" do
        expected = ["Applied Physics/Condensed Matter/Materials Science", "Physics", "Physics, Condensed Matter"]
        expect(@categories_data.map {|c| c["name"]}.sort).to eq(expected)
      end

      it "creates the journal/categories join table entry" do
        expect(@cats_journals_data.size).to eq(3)
        expect(@cats_journals_data).to include({"category_id" => "1", "journal_id" => "1"})
        expect(@cats_journals_data).to include({"category_id" => "2", "journal_id" => "1"})
        expect(@cats_journals_data).to include({"category_id" => "3", "journal_id" => "1"})
      end
    end

    context "the collections table" do
      before(:all) do
        @collections_data   = table_data("collections")
        @cols_journals_data = table_data("collections_journals")
      end

      it "creates the correct number of collections by deduplicating repeating collections" do
        expect(@collections_data.size).to eq(3)
      end

      it "creates the collections" do
        expected = ["CCPhysChemEarthSci", "ESI", "SCIE"]
        expect(@collections_data.map {|c| c["name"]}.sort).to eq(expected)
      end

      it "creates the journal/collections join table entry" do
        expect(@cols_journals_data.size).to eq(3)
        expect(@cols_journals_data).to include({"collection_id" => "1", "journal_id" => "1"})
        expect(@cols_journals_data).to include({"collection_id" => "2", "journal_id" => "1"})
        expect(@cols_journals_data).to include({"collection_id" => "3", "journal_id" => "1"})
      end
    end

    context "the publishers table" do
      before(:all) do
        @publishers_data = table_data("publishers")
      end

      it "creates the correct number of publishers by deduplicating repeating publishers" do
        expect(@publishers_data.size).to eq(1)
      end

      it "creates the publishers" do
        expected = ["HINDAWI LTD"]
        expect(@publishers_data.map {|c| c["name"]}.sort).to eq(expected)
      end
    end

    context "the publication summaries table" do
      before(:all) do
        @publication_summary_data = table_data("publication_summaries")
        @publication_summary      = @publication_summary_data.first
      end

      it "consolidates all publication entries for an institution in a month" do
        expect(@publication_summary_data.size).to eq(1)
      end

      it "has a PK" do
        expect(@publication_summary["id"]).to eq("1")
      end

      it "references a journal by FK" do
        expect(@publication_summary["journal_id"]).to eq("1")
      end

      it "records a date" do
        expect(@publication_summary["date"]).to eq("2017-01-01")
      end

      it "records and institution" do
        expect(@publication_summary["institution"]).to eq("uw")
      end

      it "sums article counts for an institution" do
        expect(@publication_summary["article_count"]).to eq("1.0")
      end

      it "sums grant article counts for an insititution" do
        expect(@publication_summary["grant_article_count"]).to eq("0.0")
      end
    end

    context "the use summaries table" do
      before(:all) do
        @use_summary_data = table_data("use_summaries")
        @use_summary      = @use_summary_data.first
      end

      it "consolidates all use entries for an institution in a month" do
        expect(@use_summary_data.size).to eq(1)
      end

      it "has a PK" do
        expect(@use_summary["id"]).to eq("1")
      end

      it "references a journal by FK" do
        expect(@use_summary["journal_id"]).to eq("1")
      end

      it "records a date" do
        expect(@use_summary["date"]).to eq("2017-01-01")
      end

      it "records and institution" do
        expect(@use_summary["institution"]).to eq("osu")
      end

      it "sums uses for an institution" do
        expect(@use_summary["use_count"]).to eq("1.0")
      end
    end

    context "the citation summaries table" do
      before(:all) do
        @citation_summary_data = table_data("citation_summaries")
        @citation_summary      = @citation_summary_data.select {|summary| summary["date"] == "2016-05-01"}.first
      end

      it "consolidates all citation entries for an institution in a month" do
        expect(@citation_summary_data.size).to eq(2)
      end

      it "has a PK" do
        expect(@citation_summary["id"]).to eq("2")
      end

      it "references a journal by FK" do
        expect(@citation_summary["journal_id"]).to eq("1")
      end

      it "records a date" do
        expect(@citation_summary["date"]).to eq("2016-05-01")
      end

      it "records and institution" do
        expect(@citation_summary["institution"]).to eq("uw")
      end

      it "sums citations for an institution but is careful to deduplicate by citation ID" do
        expect(@citation_summary["citation_count"]).to eq("2.0")
      end
    end

    context "the grants tables" do
      before(:all) do
        @grants = table_data("grants")
        @fed_reporter_agencies = table_data("fed_reporter_agencies")
        # @agency_grant_data = table_data("agencies_grants")
        @grant_journal_data = table_data("grants_journals")
      end

      it "has grant identifiers" do
        expect(@grants.first["identifiers"]).to eq("R01-1234; AB054321")
      end

      it "has grant recipient institution" do
        expect(@grants.first["institution"]).to eq("uw")
      end

      it "has a researcher submitted grant name" do
        expect(@grants.first["grant_agency_name"]).to eq("NIH BDDOC")
      end

      it "creates entries for fed reporter agencies when the data matches" do
        expect(@grants.first["fed_reporter_agency_id"]).to eq("1")
      end

      it "has mapped fed reporter agencies" do
        expect(@fed_reporter_agencies.first["name"]).to eq("Department of Health & Human Services")
      end

      it "associates the grant with the journal" do
        expect(@grant_journal_data).to include({"grant_id" => "1", "journal_id" => "1"})
      end
    end
  end
end
