require "sandbox_helper"

RSpec.describe "Search", type: :system do
  let_table_class superclass: ApplicationTable do
    include RapidTable::Search
    include RapidTable::Adapters::Array

    column :id
    column :name, searchable: true
  end

  let(:record_class) { Struct.new(:id, :name) }
  let(:records) { (1..50).map { |i| record_class.new(i, "Name #{i}.") } }

  it "allows searching by some text" do
    mock_table
    visit mocked_table_path
    expect(page).to have_text("Name 1.")
    expect(page).to have_text("Name 2.")
    expect(page).to have_text("Name 10.")

    fill_in "q", with: "1"
    submit_search_via_enter_key
    expect(page).to have_text("Name 1.")
    expect(page).not_to have_text("Name 2.")
    expect(page).to have_text("Name 10.")

    # it doesn't create a hidden field for the search param
    expect(page).not_to have_css("input[name='q'][type='hidden']", visible: false)
  end

  private

  def submit_search_via_enter_key
    find('input[type="search"]').send_keys(:enter)
  end
end
