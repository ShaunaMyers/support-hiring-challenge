require 'minitest/autorun'
require 'csv'
require 'tempfile'
require_relative '../match_users'

class MatchUsersTest < Minitest::Test
  def setup
    @temp_file = Tempfile.new(%w[test .csv])
    @temp_file.write(<<~CSV)
      first_name,last_name,phone,email,zip
      John,Doe,123-456-7890,john@example.com,12345
      Jane,Smith,987-654-3210,ane@example.com,54321
      Johnny,Doe,555-555-5555,john@example.com,12345
      Bob,Johnson,(123) 456-7890,bob@example.com,67890
    CSV
    @temp_file.close

    @output_file = "test_output.csv"
  end

  def teardown
    @temp_file.unlink
    File.delete(@output_file) if File.exist?(@output_file)
  end

  def test_match_users_class_exists
    assert_kind_of Class, MatchUsers
  end

  def test_match_users_accepts_matching_types_and_filename
    # Should not raise an error
    MatchUsers.new(['email'], @temp_file.path)
  end

  def test_match_users_validates_matching_types
    assert_raises(ArgumentError) do
      MatchUsers.new(['invalid_type'], @temp_file.path)
    end
  end
end
