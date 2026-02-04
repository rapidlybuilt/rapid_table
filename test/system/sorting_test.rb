# frozen_string_literal: true

require "test_helper"

class SortingSystemTest < ApplicationSystemTestCase
  class TestTable < ApplicationTable
    include RapidTable::Sorting
    include RapidTable::Adapters::Array

    column :id, sortable: true, sort_order: :desc
    column :name, sortable: true

    def dom_id(record)
      "id-#{record.id}"
    end
  end

  def setup
    record_class = Struct.new(:id, :name)
    self.records = (1..50).map { |i| record_class.new(i, "Name #{i}.") }
    self.table_class = TestTable
  end

  test "clicking on a column to sort by it and clicking again to reverse the sort order" do
    mock_table sort_column: :name, sort_order: :asc, skip_pagination: true

    visit mocked_table_path
    assert_sorted_table_header("Name", :asc)
    assert_sortable_table_header("Id")
    assert_appears_before("Name 1.", "Name 2.")

    click_on "Name▲"
    assert_sorted_table_header("Name", :desc)
    assert_sortable_table_header("Id")
    assert_appears_before("Name 2.", "Name 1.")

    click_on "Id"
    assert_sorted_table_header("Id", :desc)
    assert_sortable_table_header("Name")
    assert_appears_before("Name 2.", "Name 1.")

    click_on "Id"
    assert_sorted_table_header("Id", :asc)
    assert_sortable_table_header("Name")
    assert_appears_before("Name 1.", "Name 2.")
  end

  test "sorts nil values to the end" do
    records[0].name = nil

    table_class.sort_column = :name
    table_class.sort_order = :asc
    mock_table skip_pagination: true

    visit mocked_table_path
    assert_appears_before(%("id-9"), %("id-1")) # id-1 is after id-9 because it's nil
  end

  private

  def assert_sorted_table_header(label, order)
    text = order == :asc ? "#{label}▲" : "#{label} \n▼"
    assert_selector ".admin-table-header-cell-link", text: text
  end

  def assert_sortable_table_header(label)
    assert_selector ".admin-table-header-cell-link", text: "#{label}▲\n▼"
  end
end
