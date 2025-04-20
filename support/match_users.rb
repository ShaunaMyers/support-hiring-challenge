require 'csv'

class MatchUsers
  VALID_MATCHERS = ['email', 'phone']

  def initialize(matching_types, input_filename)
    @matching_types = validate_matching_types(matching_types)
    @input_filename = validate_input_file(input_filename)
  end

  def process_to_file(output_filename)
    # should we eventually set a default filename that uses timestamp?
    rows = read_csv(@input_filename)

    # Write to output file with empty user_ids for now
    write_csv(output_filename, rows, {})
  end

  private

  def validate_matching_types(types)
    types.each do |type|
      unless VALID_MATCHERS.include?(type)
        raise ArgumentError, "Invalid matching type: '#{type}'. Valid types are: #{VALID_MATCHERS.join(', ')}"
      end
    end
    types
  end

  def validate_input_file(filename)
    unless File.exist?(filename)
      raise ArgumentError, "Input file '#{filename}' does not exist"
    end
    filename
  end

  def read_csv(filename)
    rows = []
    CSV.foreach(filename, headers: true) do |row|
      rows << row.to_h
    end
    rows
  end

  def write_csv(output_filename, rows, user_ids)
    CSV.open(output_filename, 'w') do |csv|
      headers = ['user_id'] + rows.first.keys
      csv << headers

      # Write data rows with placeholder user_ids
      rows.each_with_index do |row, index|
        csv << [index + 1] + row.values
      end
    end
  end
end

# Command-line handling
if __FILE__ == $PROGRAM_NAME
  # implement later
end