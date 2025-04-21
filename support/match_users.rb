require 'csv'

class MatchUsers
  VALID_MATCHERS = %w[email phone]

  def initialize(matching_types, input_filename)
    @matching_types = validate_matching_types(matching_types)
    @input_filename = validate_input_file(input_filename)
  end

  def process_to_file(output_filename)
    rows = read_csv(@input_filename)
    return if rows.empty?

    headers = rows.first.keys
    @email_columns = identify_columns(headers, 'email')
    @phone_columns = identify_columns(headers, 'phone')

    user_ids = group_records(rows)
    write_csv(output_filename, rows, user_ids)
  end

  private

  def validate_matching_types(types)
    invalid_types = types.reject { |type| VALID_MATCHERS.include?(type) }
    unless invalid_types.empty?
      raise ArgumentError, "Invalid matching type(s): #{invalid_types.join(', ')}. Valid types are: #{VALID_MATCHERS.join(', ')}"
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
  rescue CSV::MalformedCSVError => e
    raise ArgumentError, "Error reading CSV file: #{e.message}"
  end

  def identify_columns(headers, type)
    headers.select { |header| header.to_s.downcase.include?(type) }
  end

  def normalize_phone(phone)
    # Remove all non-digit characters
    digits = phone.to_s.gsub(/\D/, '')

    # Handle US numbers with country code (leading 1)
    if digits.length == 11 && digits.start_with?('1')
      digits = digits[1..-1]
    end

    digits
  end

  def extract_values(row, columns, &transform)
    values = []
    columns.each do |col|
      if row[col] && !row[col].to_s.strip.empty?
        value = transform ? transform.call(row[col]) : row[col]
        values << value
      end
    end
    values
  end

  def get_emails(row)
    extract_values(row, @email_columns) { |val| val.downcase.strip }
  end

  def get_phones(row)
    extract_values(row, @phone_columns) { |val| normalize_phone(val) }
  end

  def find_group_id(identifiers, id_to_group)
    identifiers.each do |identifier|
      return id_to_group[identifier] if id_to_group[identifier]
    end
    nil
  end

  def update_mappings(identifiers, id_to_group, group_id)
    identifiers.each do |identifier|
      id_to_group[identifier] = group_id
    end
  end

  def find_existing_group(row, email_to_group, phone_to_group)
    if @matching_types.include?('email')
      emails = get_emails(row)
      group_id = find_group_id(emails, email_to_group)
      return group_id if group_id
    end

    if @matching_types.include?('phone')
      phones = get_phones(row)
      group_id = find_group_id(phones, phone_to_group)
      return group_id if group_id
    end

    nil
  end

  def update_all_mappings(row, email_to_group, phone_to_group, group_id)
    if @matching_types.include?('email')
      emails = get_emails(row)
      update_mappings(emails, email_to_group, group_id)
    end

    if @matching_types.include?('phone')
      phones = get_phones(row)
      update_mappings(phones, phone_to_group, group_id)
    end
  end

  def group_records(rows)
    record_to_group = {}
    email_to_group = {}
    phone_to_group = {}
    next_group_id = 1

    rows.each_with_index do |row, index|
      # Try to find an existing group
      group_id = find_existing_group(row, email_to_group, phone_to_group)

      # Create a new group if needed
      if group_id.nil?
        group_id = next_group_id
        next_group_id += 1
      end

      # Assign this record to the group
      record_to_group[index] = group_id

      # Update all mappings
      update_all_mappings(row, email_to_group, phone_to_group, group_id)
    end

    record_to_group
  end

  def write_csv(output_filename, rows, user_ids)
    CSV.open(output_filename, 'w') do |csv|
      headers = ['UserId'] + rows.first.keys
      csv << headers

      rows_with_ids = rows.each_with_index.map do |row, index|
        user_id = user_ids[index] || (index + 1)
        [user_id, row, index]
      end

      rows_with_ids.sort_by! { |user_id, _, _| user_id }

      rows_with_ids.each do |user_id, row, _|
        csv << [user_id] + row.values
      end
    end
  rescue => e
    raise "Error writing to output file: #{e.message}"
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
