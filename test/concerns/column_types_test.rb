# frozen_string_literal: true

require "test_helper"

module ColumnTypesTest
  Record = Struct.new(:string_val, :integer_val, :float_val, :date_val, :datetime_val, :boolean_val, :currency_val, :percentage_val)

  class TypesTest < ActiveSupport::TestCase
    def setup
      @table_class = Class.new RapidTable::Base do
        include RapidTable::Columns
        include RapidTable::ColumnTypes

        columns do |t|
          t.string :string_val
          t.integer :integer_val
          t.float :float_val
          t.date :date_val
          t.datetime :datetime_val
          t.boolean :boolean_val
          t.currency :currency_val
          t.percentage :percentage_val
        end
      end
    end

    # String type tests
    test "string type converts value to string" do
      record = Record.new("hello", nil, nil, nil, nil, nil, nil, nil)
      table = @table_class.new([record])
      assert_equal "hello", table.column_cell_html(record, @table_class.find_column!(:string_val))
    end

    test "string type converts non-string values" do
      record = Record.new(123, nil, nil, nil, nil, nil, nil, nil)
      table = @table_class.new([record])
      assert_equal "123", table.column_cell_html(record, @table_class.find_column!(:string_val))
    end

    # Integer type tests
    test "integer type formats with thousands separators" do
      record = Record.new(nil, 1_234_567, nil, nil, nil, nil, nil, nil)
      table = @table_class.new([record])
      assert_equal "1,234,567", table.column_cell_html(record, @table_class.find_column!(:integer_val))
    end

    test "integer type handles small numbers" do
      record = Record.new(nil, 42, nil, nil, nil, nil, nil, nil)
      table = @table_class.new([record])
      assert_equal "42", table.column_cell_html(record, @table_class.find_column!(:integer_val))
    end

    test "integer type handles negative numbers" do
      record = Record.new(nil, -1_234, nil, nil, nil, nil, nil, nil)
      table = @table_class.new([record])
      assert_equal "-1,234", table.column_cell_html(record, @table_class.find_column!(:integer_val))
    end

    # Float type tests
    test "float type formats with two decimal places" do
      record = Record.new(nil, nil, 1234.5, nil, nil, nil, nil, nil)
      table = @table_class.new([record])
      assert_equal "1,234.50", table.column_cell_html(record, @table_class.find_column!(:float_val))
    end

    test "float type handles whole numbers" do
      record = Record.new(nil, nil, 100, nil, nil, nil, nil, nil)
      table = @table_class.new([record])
      assert_equal "100.00", table.column_cell_html(record, @table_class.find_column!(:float_val))
    end

    test "float type handles negative numbers" do
      record = Record.new(nil, nil, -1234.567, nil, nil, nil, nil, nil)
      table = @table_class.new([record])
      assert_equal "-1,234.57", table.column_cell_html(record, @table_class.find_column!(:float_val))
    end

    # Date type tests
    test "date type formats in human-readable format" do
      record = Record.new(nil, nil, nil, Date.new(2024, 1, 15), nil, nil, nil, nil)
      table = @table_class.new([record])
      result = table.column_cell_html(record, @table_class.find_column!(:date_val))
      assert_includes result, "January"
      assert_includes result, "15"
      assert_includes result, "2024"
    end

    test "date type converts datetime to date" do
      record = Record.new(nil, nil, nil, DateTime.new(2024, 6, 20, 14, 30), nil, nil, nil, nil)
      table = @table_class.new([record])
      result = table.column_cell_html(record, @table_class.find_column!(:date_val))
      assert_includes result, "June"
      assert_includes result, "20"
      assert_includes result, "2024"
    end

    # Datetime type tests
    test "datetime type formats with date and time" do
      record = Record.new(nil, nil, nil, nil, DateTime.new(2024, 1, 15, 14, 30), nil, nil, nil)
      table = @table_class.new([record])
      result = table.column_cell_html(record, @table_class.find_column!(:datetime_val))
      assert_includes result, "January"
      assert_includes result, "15"
      assert_includes result, "2024"
      # Time can be 12-hour (2:30 PM) or 24-hour (14:30) depending on I18n config
      assert_match(/14:30|2:30/, result)
    end

    test "datetime type handles Time objects" do
      record = Record.new(nil, nil, nil, nil, Time.new(2024, 3, 10, 9, 15), nil, nil, nil)
      table = @table_class.new([record])
      result = table.column_cell_html(record, @table_class.find_column!(:datetime_val))
      assert_includes result, "March"
      assert_includes result, "10"
      # Time can be 12-hour (9:15 AM) or 24-hour (09:15) depending on I18n config
      assert_match(/09:15|9:15/, result)
    end

    # Boolean type tests
    test "boolean type renders true as Yes" do
      record = Record.new(nil, nil, nil, nil, nil, true, nil, nil)
      table = @table_class.new([record])
      assert_equal "Yes", table.column_cell_html(record, @table_class.find_column!(:boolean_val))
    end

    test "boolean type renders false as No" do
      record = Record.new(nil, nil, nil, nil, nil, false, nil, nil)
      table = @table_class.new([record])
      assert_equal "No", table.column_cell_html(record, @table_class.find_column!(:boolean_val))
    end

    # Currency type tests
    test "currency type formats with dollar sign" do
      record = Record.new(nil, nil, nil, nil, nil, nil, 1234.5, nil)
      table = @table_class.new([record])
      assert_equal "$1,234.50", table.column_cell_html(record, @table_class.find_column!(:currency_val))
    end

    test "currency type handles negative values" do
      record = Record.new(nil, nil, nil, nil, nil, nil, -99.99, nil)
      table = @table_class.new([record])
      assert_equal "-$99.99", table.column_cell_html(record, @table_class.find_column!(:currency_val))
    end

    # Percentage type tests
    test "percentage type formats decimal as percentage" do
      record = Record.new(nil, nil, nil, nil, nil, nil, nil, 0.75)
      table = @table_class.new([record])
      assert_equal "75.00%", table.column_cell_html(record, @table_class.find_column!(:percentage_val))
    end

    test "percentage type handles whole number percentages" do
      record = Record.new(nil, nil, nil, nil, nil, nil, nil, 75)
      table = @table_class.new([record])
      assert_equal "75.00%", table.column_cell_html(record, @table_class.find_column!(:percentage_val))
    end

    test "percentage type handles negative decimals" do
      record = Record.new(nil, nil, nil, nil, nil, nil, nil, -0.25)
      table = @table_class.new([record])
      assert_equal "-25.00%", table.column_cell_html(record, @table_class.find_column!(:percentage_val))
    end

    test "percentage type handles values over 100%" do
      record = Record.new(nil, nil, nil, nil, nil, nil, nil, 150)
      table = @table_class.new([record])
      assert_equal "150.00%", table.column_cell_html(record, @table_class.find_column!(:percentage_val))
    end
  end
end
