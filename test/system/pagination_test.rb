# frozen_string_literal: true

require "test_helper"

class PaginationSystemTest < ApplicationSystemTestCase
  class TestTable < ApplicationTable
    include RapidTable::Columns
    include RapidTable::Ext::Pagination
    include RapidTable::Adapters::Array

    column :id
    column :name
  end

  def setup
    record_class = Struct.new(:id, :name)
    self.records = (1..250).map { |i| record_class.new(i, "Name #{i}.") }
    self.table_class = TestTable
    @pages = records.each_slice(25).to_a
  end

  # Pagination links tests
  test "navigates to specific pages" do
    mock_table
    visit mocked_table_path
    assert_page_has_all_records @pages.first

    click_on "Next"
    assert_page_has_all_records @pages.second

    click_on "Prev"
    assert_page_has_all_records @pages.first

    click_on "Last"
    assert_page_has_all_records @pages.last

    click_on "First"
    assert_page_has_all_records @pages.first

    click_on "3"
    assert_page_has_all_records @pages.third
  end

  test "shows a subset of the possible pages to navigate directly to" do
    mock_table
    visit mocked_table_path

    within ".pagination" do
      assert_selector "span.page.current", text: "1"
      assert_no_link "First"
      assert_no_link "Prev"

      %w[2 3 4 5 Next Last].each do |link|
        assert_link link
      end
    end

    visit mocked_table_path(page: 6)
    within ".pagination" do
      assert_selector "span.page.current", text: "6"
      %w[First Prev 2 3 4 5 7 8 9 10 Next Last].each do |link|
        assert_link link
      end
    end

    visit mocked_table_path(page: @pages.length)
    within ".pagination" do
      assert_selector "span.page.current", text: "10"
      assert_no_link "Next"
      assert_no_link "Last"
      %w[First Prev 6 7 8 9].each do |link|
        assert_link link
      end
    end
  end

  test "allows decreasing the number of siblings near the current page" do
    mock_table pagination_siblings_count: 2
    visit mocked_table_path(page: 6)

    within ".pagination" do
      assert_selector "span.page.current", text: "6"
      %w[First Prev 4 5 7 8 Next Last].each do |link|
        assert_link link
      end
      %w[2 3 9 10].each do |link|
        assert_no_link link
      end
    end
  end

  test "removes the gap indicator when there are no siblings" do
    mock_table pagination_siblings_count: 0
    visit mocked_table_path(page: 6)

    within ".pagination" do
      %w[First Prev Next Last].each do |link|
        assert_link link
      end
      %w[2 3 4 5 7 8 9 10].each do |link|
        assert_no_link link
      end
      assert_no_text "…"
    end
  end

  # Per page select tests
  test "shows the per page select" do
    mock_table
    visit mocked_table_path
    assert_select "Per Page", options: %w[25 50 100]
  end

  test "updates the per page" do
    mock_table
    visit mocked_table_path
    select "50", from: "Per Page"
    assert_page_has_all_records records.first(50)
  end

  private

  def assert_page_has_all_records(records)
    records.each do |record|
      assert_text record.name
    end
  end
end
