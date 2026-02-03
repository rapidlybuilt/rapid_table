require "sandbox_helper"

RSpec.describe "Export", type: :system, nojs: true do
  let_table_class superclass: ApplicationTable do
    include RapidTable::Export
    include RapidTable::Ext::Array

    column :id
    column :name
  end

  let(:record_class) { Struct.new(:id, :name) }
  let(:records) { (1..50).map { |i| record_class.new(i, "Name #{i}.") } }

  it "exports the table to a CSV file" do
    mock_table
    visit mocked_table_path
    click_on "CSV"
    expect(page.body).to have_csv_row("id", "name")
    expect(page.body).to have_csv_row("1", "Name 1.")
    expect(page.body).to have_csv_row("50", "Name 50.")
  end

  it "exports the table to JSON content" do
    mock_table
    visit mocked_table_path
    click_on "JSON"
    expect(page_json).to include("id" => 1, "name" => "Name 1.")
    expect(page_json).to include("id" => 50, "name" => "Name 50.")
  end

  private

  def have_csv_row(*values)
    include(CSV.generate { |csv| csv << values })
  end

  def page_json
    JSON.parse(page.body)
  end
end
