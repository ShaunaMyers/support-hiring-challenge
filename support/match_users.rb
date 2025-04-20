require 'csv'

class MatchUsers
  VALID_MATCHERS = %w[email phone]

  def initialize(matching_types, input_filename)
    @matching_types = validate_matching_types(matching_types)
    @input_filename = validate_input_file(input_filename)
  end

  def process_to_file(output_filename)
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

  def normalize_phone(phone)
    phone.to_s.gsub(/\D/, '')
  end

  def group_records(rows)
    record_to_group = {}
    email_to_group = {}
    phone_to_group = {}
    next_group_id = 1

    rows.each_with_index do |row, index|
      group_id = nil

      if @matching_types.include?('email') && row['Email']
        email_key = row['Email'].downcase.strip
        if email_to_group[email_key]
          group_id = email_to_group[email_key]
        end
      end

      if group_id.nil? && @matching_types.include?('phone') && row['Phone']
        phone_key = normalize_phone(row['Phone'])
        if phone_to_group[phone_key]
          group_id = phone_to_group[phone_key]
        end
      end

      if group_id.nil?
        group_id = next_group_id
        next_group_id += 1
      end

      record_to_group[index] = group_id

      if @matching_types.include?('email') && row['Email']
        email_key = row['Email'].downcase.strip
        email_to_group[email_key] = group_id
      end

      if @matching_types.include?('phone') && row['Phone']
        phone_key = normalize_phone(row['Phone'])
        phone_to_group[phone_key] = group_id
      end
    end

    record_to_group
  end

  def write_csv(output_filename, rows, user_ids)
    CSV.open(output_filename, 'w') do |csv|
      headers = ['UserId'] + rows.first.keys
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
  if ARGV.length < 2
    puts "Usage: ruby match_users.rb <one_or_more_matching_types> <input_filename.csv>"
    puts "Example: ruby match_users.rb email phone input.csv"
    exit 1
  end

  matching_types = ARGV[0..-2]
  input_filename = ARGV[-1]

  output_filename = "matched_#{Time.now.strftime('%Y%m%d%H%M%S')}_#{File.basename(input_filename)}"

  begin
    matcher = MatchUsers.new(matching_types, input_filename)
    matcher.process_to_file(output_filename)

    puts "Processing complete. Results saved to '#{output_filename}'."
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end
