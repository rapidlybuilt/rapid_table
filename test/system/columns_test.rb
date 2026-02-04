# frozen_string_literal: true

require "test_helper"

class ColumnsSystemTest < ApplicationSystemTestCase
  class TestTable < ApplicationTable
    include RapidTable::Columns
    include RapidTable::Adapters::Array

    column :id
    column :name
  end

  class TestTableWithIdCell < TestTable
    column :id, html_cell_method: :id_cell

    def id_cell(record, column)
      "ID: #{record.id}."
    end
  end

  class TestTableWithStringCell < TestTable
    def string_cell(value)
      "String: #{value}."
    end
  end

  class TestTableWithExplicitLabel < TestTable
    column :id, label: "Identifier"
  end

  def setup
    record_class = Struct.new(:id, :name)
    self.records = (1..50).map { |i| record_class.new(i, "Name #{i}.") }
    self.table_class = TestTable
  end

  # Labels tests
  test "tries an explicit label first" do
    self.table_class = TestTableWithExplicitLabel
    mock_table
    visit mocked_table_path
    assert_no_text "ID"
    assert_text "Identifier"
  end

  test "then tries I18n for labels" do
    mock_translation "rapid_table.columns_system_test/test_table.columns.id", "Identifier"
    mock_table
    visit mocked_table_path
    assert_no_text "ID"
    assert_text "Identifier"
  end

  test "then falls back to titleize" do
    mock_table
    visit mocked_table_path
    assert_text "Id"
  end

  # Cell rendering tests
  test "allows explicit column cell methods" do
    self.table_class = TestTableWithIdCell
    mock_table
    visit mocked_table_path
    assert_text "ID: 1."
    assert_text "ID: 2."
  end

  test "allows explicit column type methods" do
    self.table_class = TestTableWithStringCell
    mock_table
    visit mocked_table_path
    assert_text "String: Name 1.."
    assert_text "String: Name 2.."
  end

  # Filtering tests
  test "allows showing only certain columns" do
    mock_table only: [:id]
    visit mocked_table_path
    assert_text "Id"
    assert_no_text "Name"
  end

  test "allows showing all except certain columns" do
    mock_table except: [:name]
    visit mocked_table_path
    assert_text "Id"
    assert_no_text "Name"
  end
end
