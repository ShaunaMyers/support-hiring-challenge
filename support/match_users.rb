require 'csv'

class MatchUsers
  VALID_MATCHERS = ['email', 'phone']

  def initialize(matching_types, input_filename)
    @matching_types = validate_matching_types(matching_types)
    @input_filename = input_filename
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
end

# Command-line handling
if __FILE__ == $PROGRAM_NAME
  # implement later
end