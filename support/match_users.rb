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
    user_ids = group_records(rows)

    write_csv(output_filename, rows, user_ids)
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

  def group_records(rows)
    record_to_group = {}
    groups = {}
    next_group_id = 1

    rows.each_with_index do |row, index|
      group_id = nil

      if @matching_types.include?('email') && row['email']
        email_key = row['email'].downcase.strip
        if groups[:email] && groups[:email][email_key]
          group_id = groups[:email][email_key]
        end
      end

      if group_id.nil?
        group_id = next_group_id
        next_group_id += 1
      end

      record_to_group[index] = group_id

      if @matching_types.include?('email') && row['email']
        email_key = row['email'].downcase.strip
        groups[:email] ||= {}
        groups[:email][email_key] = group_id
      end
    end

    record_to_group
  end

  def write_csv(output_filename, rows, user_ids)
    CSV.open(output_filename, 'w') do |csv|
      headers = ['user_id'] + rows.first.keys
      csv << headers

      rows.each_with_index do |row, index|
        user_id = user_ids[index] || (index + 1)
        csv << [user_id] + row.values
      end
    end
  end
end

# Command-line handling
if __FILE__ == $PROGRAM_NAME
  # implement later
end