module Encomium
  module MARC
    class BibRecord

      TOP_LC_CLASS_PATTERN = /^([A-Z]+)([0-9]+(\.[0-9]+)*).*/

      attr_reader :title, :issns, :oclc_numbers, :lc_classes, :type

      def initialize(marc_record)
        @record = marc_record
        parse
      end


      def to_json
        self.instance_variables.select {|var| var != :@record}
            .reduce(Hash.new) {|h, var| h[var.to_s[1..-1]] = self.instance_variable_get(var); h}
            .to_json
      end


      private


      def parse
        @title        = remove_trailing_punct(@record["245"]["a"])
        @issns        = field_spec_values(@record, "022a:022e:776x")
        @oclc_numbers = self.primary_oclc_numbers + self.related_oclc_numbers
        @lc_classes   = parse_lc_classes
        @type         = "BibRecord"
      end


      def parse_lc_classes
        field_spec_values(@record, "050a:090a")
            .map {|lc_class|   lc_class.gsub(/[\[\]]/, "")}
            .map {|lc_class|   lc_class.match(TOP_LC_CLASS_PATTERN)}
            .map {|match_data| match_data.nil? ? nil : match_data[1] + match_data[2]}
            .compact
            .uniq
      end


      def primary_oclc_numbers
        @record.fields("035")
            .map {|ctrl_num| subfields_array(ctrl_num, ["a"])}
            .flatten
            .select {|num| num.start_with?("(OCoLC)") or num.start_with?(/oc*[mn]/)}
            .map {|num| num.gsub(/\D/, "").to_i}
            .uniq
      end


      def related_oclc_numbers
        @record.fields("776").map {|ctrl_num| subfields_array(ctrl_num, ["w"])}.flatten
               .select {|num| num.start_with?("(OCoLC)") or num.start_with?(/oc*[mn]/)}
               .map {|num| num.gsub(/\D/, "").to_i}
               .uniq
      end

      def field_spec_values(record, field_spec, options = {})
        rejoin_delimiter = options[:delimiter].nil? ? " " : options[:delimiter]
        # An array for the values eventually to be returned
        field_values = Array.new
        # Parse the entire fieldspec into component pieces and loop over them
        # "100abcdq:110abd:111abd" => ["100abcdq", "110abd", "111abd"]
        field_spec.split(":").each do |sub_spec|
          field_tag = sub_spec[0,3]            # => "100"
          sf_codes = sub_spec[3..-1].split("") # => ["a", "b", "c", "d", "q"]
          # Find all occurence of the the current field tag.
          record.fields(field_tag).each do |field|
            field_str     = subfields_str(field, sf_codes, rejoin_delimiter)
            field_values << field_str unless field_str.nil?
          end
        end
        field_values
      end


      def subfields_str(field, sf_codes, delimiter)
        sub_values = subfields_array(field, sf_codes)
        sub_values.size == 0 ? nil : remove_trailing_punct(sub_values.join(delimiter))
      end


      def subfields_array(field, sf_codes)
        field.subfields.select {|sf| sf_codes.include?(sf.code)}.map {|sf| sf.value}
      end


      def remove_trailing_punct(str, punct_to_remove = /[[:punct:]]$/)
        str.strip.match(/[\/:,.]$/) ? str.strip[0..-2].strip : str.strip
      end
    end
  end
end
