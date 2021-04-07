# Encomium

This codebase merges publishing data together to analyze institutional citation patterns. It is being developed for a project to analyze BTAA publishing trends.

## Installation

Clone this gem locally.

## Usage

1. After cloning the repo, setup the input data directory per instructions below
2. Save a copy of the example config file `files.yml.example` as `files.yml` [1]
3. Run the rake task: `rake build`
4. Run the rake task: `rake db_tables`

The first rake task merges all the data together and creates a pair of summary CSV data files for review. The second task produces TSV files intended to be loaded as a relational database based on the same data. This latter task creates files based on a highly normalized relational schema. The table columns use the Ruby on Rails naming conventions:

* lowercase fields
* fields use snake_case for multiple words
* table names (the TSV files in this case) are assumed to be pluralized nouns
* primary keys are always `id`
* foreign keys are always `{singular_form_of_pluralized_source_table_name}_id`
* many-to-many tables use foreign keys described as above and are named by joining the table names in alphabetical order with an underscore `_` (e.g., snake-cased)

In order to keep the files small timestamp fields are not included.

[1] Leave the original file in place because it is in the repository.

### Input Data Directory Structure

Choose a base directory on your file system and create the following sub-folders:

```
base_directory/
  +- articles/
     +- inst_1/
     +- inst_2/
     +- ...
  +- cited-articles/
  +- COUNTER/
     +- inst_1/
     +- inst_2/
     +- ...
  +- MARC/
  +- output/
  +- wos-journals/
```

**articles:** WOS JSON files for articles published *authored by* the institutions being studied. all article data files should be contained in sub-directories that use the institution codes (e.g., uw, osu, mn).

**cited-articles:** WOS JSON files for the articles *cited by* the articles in the `articles` directory

**COUNTER:** COUNTER data for the institutions being studied. all COUNTER data files should be contained in sub-directories that use the institution codes (e.g., uw, osu, mn). COUNTER data should be CSV data containing the following columns (other columns will be ignored):

* Journal Title (optional)
* Publisher (optional)
* ISSN
* eISSN (optional)
* Date in the format YYYY-MM-DD (assumed to be month-level granularity only)
* Uses (SUM)

**MARC:** any files containing binary MARC records primarily used to identify LC Classification numbers

**output:** this file will be generated when the Rake tasks are run and will contain all processed data, some of which is derivative representations for processing and some of which will be used for final output

**wos-journals:** CSV files downloaded from Clarivate's website. These files determine which journals will be included in the final analysis files. All other data files match these title lists by ISSN.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Encomium project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/encomium/blob/master/CODE_OF_CONDUCT.md).
