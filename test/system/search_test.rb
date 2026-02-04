# frozen_string_literal: true

require "test_helper"

class SearchSystemTest < ApplicationSystemTestCase
  class TestTable < ApplicationTable
    include RapidTable::Search
    include RapidTable::Adapters::Array

    column :id
    column :name, searchable: true
  end

  def setup
    record_class = Struct.new(:id, :name)
    self.records = (1..50).map { |i| record_class.new(i, "Name #{i}.") }
    self.table_class = TestTable
  end

  test "allows searching by some text" do
    mock_table
    visit mocked_table_path
    assert_text "Name 1."
    assert_text "Name 2."
    assert_text "Name 10."

    fill_in "q", with: "1"
    submit_search_via_enter_key
    assert_text "Name 1."
    assert_no_text "Name 2."
    assert_text "Name 10."

    # it doesn't create a hidden field for the search param
    assert_no_selector "input[name='q'][type='hidden']", visible: false
  end

  private

  def submit_search_via_enter_key
    find('input[type="search"]').send_keys(:enter)
  end
end
