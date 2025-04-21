require 'minitest/autorun'
require 'csv'
require 'tempfile'
require_relative '../match_users'

class MatchUsersTest < Minitest::Test
  def setup
    @temp_file = Tempfile.new(%w[test .csv])
    @temp_file.write(<<~CSV)
      FirstName,LastName,Phone,Email,Zip
      John,Doe,123-456-7890,john@example.com,12345
      Jane,Smith,987-654-3210,ane@example.com,54321
      Johnny,Doe,555-555-5555,john@example.com,12345
      Jonathan,Doe,(123) 456-7890,jonathan@example.com,67890
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

  def test_match_users_validates_input_file_exists
    assert_raises(ArgumentError) do
      MatchUsers.new(['email'], 'nonexistent_file.csv')
    end
  end

  def test_match_users_can_process_file
    matcher = MatchUsers.new(['email'], @temp_file.path)
    matcher.process_to_file(@output_file)
    assert File.exist?(@output_file)
  end

  def test_output_file_has_user_id_column
    matcher = MatchUsers.new(['email'], @temp_file.path)
    matcher.process_to_file(@output_file)

    headers = CSV.read(@output_file, headers: true).headers
    assert_includes headers, 'UserId'
  end

  def test_email_matching_groups_same_emails
    matcher = MatchUsers.new(['email'], @temp_file.path)
    matcher.process_to_file(@output_file)

    rows = CSV.read(@output_file, headers: true)

    # Find rows with the same email
    john_row = rows.find { |row| row['FirstName'] == 'John' }
    johnny_row = rows.find { |row| row['FirstName'] == 'Johnny' }

    # They should have the same user_id
    assert_equal john_row['UserId'], johnny_row['UserId']
  end

  def test_phone_matching_groups_same_phones
    matcher = MatchUsers.new(['phone'], @temp_file.path)
    matcher.process_to_file(@output_file)

    rows = CSV.read(@output_file, headers: true)

    # Find rows with the same phone (after normalization)
    john_row = rows.find { |row| row['FirstName'] == 'John' }
    jonathan_row = rows.find { |row| row['FirstName'] == 'Jonathan' }

    # They should have the same user_id
    assert_equal john_row['UserId'], jonathan_row['UserId']
  end

  def test_multiple_matching_types
    matcher = MatchUsers.new(%w[email phone], @temp_file.path)
    matcher.process_to_file(@output_file)

    rows = CSV.read(@output_file, headers: true)

    # With both matchers, John, Johnny, and Jonathan should be in the same group
    john_row = rows.find { |row| row['FirstName'] == 'John' }
    johnny_row = rows.find { |row| row['FirstName'] == 'Johnny' }
    jonathan_row = rows.find { |row| row['FirstName'] == 'Jonathan' }

    assert_equal john_row['UserId'], johnny_row['UserId']
    assert_equal john_row['UserId'], jonathan_row['UserId']
  end

  def test_handles_empty_csv_file
    empty_file = Tempfile.new(%w[empty .csv])
    empty_file.write("FirstName,LastName,Phone,Email,Zip\n")
    empty_file.close

    matcher = MatchUsers.new(['email'], empty_file.path)
    # The method should return early without creating an output file
    matcher.process_to_file(@output_file)

    # Assert that the output file doesn't exist, as expected
    refute File.exist?(@output_file)

    empty_file.unlink
  end

  def test_handles_csv_with_no_matching_columns
    no_match_file = Tempfile.new(%w[no_match .csv])
    no_match_file.write(<<~CSV)
    FirstName,LastName,Address,Zip
    John,Doe,123 Main St,12345
    Jane,Smith,456 Oak Ave,54321
  CSV
    no_match_file.close

    matcher = MatchUsers.new(['email'], no_match_file.path)
    matcher.process_to_file(@output_file)

    assert File.exist?(@output_file)

    rows = CSV.read(@output_file, headers: true)
    user_ids = rows.map { |row| row['UserId'] }.uniq
    assert_equal rows.count, user_ids.count

    no_match_file.unlink
  end

  def test_phone_normalization
    phone_file = Tempfile.new(%w[phone .csv])
    phone_file.write(<<~CSV)
    FirstName,LastName,Phone
    John,Doe,123-456-7890
    Jane,Smith,(123) 456-7890
    Bob,Johnson,1234567890
    Alice,Brown,1-123-456-7890
  CSV
    phone_file.close

    matcher = MatchUsers.new(['phone'], phone_file.path)
    matcher.process_to_file(@output_file)

    rows = CSV.read(@output_file, headers: true)
    user_ids = rows.map { |row| row['UserId'] }.uniq
    assert_equal 1, user_ids.count

    phone_file.unlink
  end

  def test_case_insensitive_email_matching
    email_file = Tempfile.new(%w[email .csv])
    email_file.write(<<~CSV)
    FirstName,LastName,Email
    John,Doe,John@Example.com
    Jane,Smith,john@example.com
  CSV
    email_file.close

    matcher = MatchUsers.new(['email'], email_file.path)
    matcher.process_to_file(@output_file)

    rows = CSV.read(@output_file, headers: true)
    user_ids = rows.map { |row| row['UserId'] }.uniq
    assert_equal 1, user_ids.count

    email_file.unlink
  end

  def test_identifies_columns_with_different_names
    column_file = Tempfile.new(%w[columns .csv])
    column_file.write(<<~CSV)
    FirstName,LastName,WorkPhone,HomePhone,PersonalEmail,WorkEmail
    John,Doe,123-456-7890,987-654-3210,john@example.com,john@work.com
  CSV
    column_file.close

    matcher = MatchUsers.new(['phone', 'email'], column_file.path)
    matcher.process_to_file(@output_file)

    rows = CSV.read(@output_file, headers: true)
    assert_equal 1, rows.count

    column_file.unlink
  end

  def test_handles_empty_values
    empty_values_file = Tempfile.new(%w[empty_values .csv])
    empty_values_file.write(<<~CSV)
    FirstName,LastName,Phone,Email
    John,Doe,,john@example.com
    Jane,Smith,123-456-7890,
    Bob,Johnson,,
  CSV
    empty_values_file.close

    matcher = MatchUsers.new(['phone', 'email'], empty_values_file.path)
    matcher.process_to_file(@output_file)

    rows = CSV.read(@output_file, headers: true)
    # John and Jane should be in different groups, Bob in a third
    user_ids = rows.map { |row| row['UserId'] }.uniq
    assert_equal 3, user_ids.count

    empty_values_file.unlink
  end
end
