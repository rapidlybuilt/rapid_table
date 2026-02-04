# frozen_string_literal: true

require "test_helper"
require "csv"

class ExportSystemTest < NoJsSystemTestCase
  class TestTable < ApplicationTable
    include RapidTable::Export
    include RapidTable::Adapters::Array

    column :id
    column :name
  end

  def setup
    record_class = Struct.new(:id, :name)
    self.records = (1..50).map { |i| record_class.new(i, "Name #{i}.") }
    self.table_class = TestTable
  end

  test "exports the table to a CSV file" do
    mock_table
    visit mocked_table_path
    click_on "CSV"
    assert_csv_row("id", "name")
    assert_csv_row("1", "Name 1.")
    assert_csv_row("50", "Name 50.")
  end

  test "exports the table to JSON content" do
    mock_table
    visit mocked_table_path
    click_on "JSON"
    json = JSON.parse(page.body)
    assert_includes json, { "id" => 1, "name" => "Name 1." }
    assert_includes json, { "id" => 50, "name" => "Name 50." }
  end

  private

  def assert_csv_row(*values)
    expected_row = CSV.generate { |csv| csv << values }
    assert_includes page.body, expected_row
  end
end
