require "sandbox_helper"

RSpec.describe "Bulk Actions", type: :system do
  let_table_class superclass: ApplicationTable do
    include RapidTable::BulkActions
    include RapidTable::Adapters::Array

    column :id
    column :name

    bulk_action :rename
    bulk_action :delete

    def record_id(record)
      record.id
    end
  end

  let(:record_class) { Struct.new(:id, :name) }
  let(:records) { (1..50).map { |i| record_class.new(i, "Name #{i}.") } }

  it "performs bulk actions on the controller" do
    expect(MockedTablesController).to receive(:perform_bulk_action).with("rename", ["5", "10"]) do |action, ids|
      records[4].name = "Renamed 5."
      records[9].name = "Renamed 10."
    end

    mock_table
    visit mocked_table_path
    select "Rename", from: "bulk_actions"
    check "test_table_select_5"
    check "test_table_select_10"
    click_on "Perform Bulk Action"
    expect(page).to have_content("Renamed 5.")
    expect(page).to have_content("Renamed 10.")
  end
end
