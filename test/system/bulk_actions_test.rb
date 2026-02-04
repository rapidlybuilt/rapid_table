# frozen_string_literal: true

require "test_helper"

class BulkActionsSystemTest < ApplicationSystemTestCase
  class TestTable < ApplicationTable
    include RapidTable::Ext::BulkActions
    include RapidTable::Adapters::Array

    column :id
    column :name

    bulk_action :rename
    bulk_action :delete

    def record_id(record)
      record.id
    end
  end

  def setup
    record_class = Struct.new(:id, :name)
    self.records = (1..50).map { |i| record_class.new(i, "Name #{i}.") }
    self.table_class = TestTable
  end

  test "performs bulk actions on the controller" do
    # Set up the mock to capture the bulk action call
    records_ref = records
    MockedTablesController.define_singleton_method(:perform_bulk_action) do |action, ids|
      records_ref[4].name = "Renamed 5."
      records_ref[9].name = "Renamed 10."
    end

    mock_table
    visit mocked_table_path
    select "Rename", from: "bulk_actions"
    check "bulk_actions_system_test/test_table_select_5"
    check "bulk_actions_system_test/test_table_select_10"
    click_on "Perform Bulk Action"
    assert_text "Renamed 5."
    assert_text "Renamed 10."
  ensure
    # Reset the singleton method
    MockedTablesController.define_singleton_method(:perform_bulk_action) do |action, ids|
      raise NotImplementedError
    end
  end
end
