require "sandbox_helper"

RSpec.describe "Pagination", type: :system do
  let_table_class superclass: ApplicationTable do
    include RapidTable::Columns
    extend RapidTable::DSL::Pagination

    include RapidTable::Ext::Array

    column :id
    column :name
  end

  let(:record_class) { Struct.new(:id, :name) }
  let(:records) { (1..250).map { |i| record_class.new(i, "Name #{i}.") } }
  let(:pages) { records.each_slice(25).to_a }

  describe "pagination links" do
    before { mock_table } 

    it "navigates to specific pages" do
      visit mocked_table_path
      expect_page_to_have_all_records pages.first
      click_on "Next"
      expect_page_to_have_all_records pages.second
      click_on "Prev"
      expect_page_to_have_all_records pages.first
      click_on "Last"
      expect_page_to_have_all_records pages.last
      click_on "First"
      expect_page_to_have_all_records pages.first
      click_on "3"
      expect_page_to_have_all_records pages.third
    end

    it "shows a subset of the possible pages to navigate directly to" do
      visit mocked_table_path
      within ".pagination" do
        expect(page).to have_css("span.page.current", text: "1")
        expect(page).not_to have_link("First")
        expect(page).not_to have_link("Prev")

        %w[2 3 4 5 Next Last].each do |link|
          expect(page).to have_link(link)
        end
      end

      visit mocked_table_path(page: 6)
      within ".pagination" do
        expect(page).to have_css("span.page.current", text: "6")
        %w[First Prev 2 3 4 5 7 8 9 10 Next Last].each do |link|
          expect(page).to have_link(link)
        end
      end

      visit mocked_table_path(page: pages.length)
      within ".pagination" do
        expect(page).to have_css("span.page.current", text: "10")
        expect(page).not_to have_link("Next")
        expect(page).not_to have_link("Last")
        %w[First Prev 6 7 8 9].each do |link|
          expect(page).to have_link(link)
        end
      end
    end

    it "allows decreasing the number of siblings near the current page" do
      table_class.pagination_siblings_count = 2
      visit mocked_table_path(page: 6)
      within ".pagination" do
        # puts page.body
        expect(page).to have_css("span.page.current", text: "6")
        %w[First Prev 4 5 7 8 Next Last].each do |link|
          expect(page).to have_link(link)
        end
        %w[2 3 9 10].each do |link|
          expect(page).not_to have_link(link)
        end
      end
    end

    it "removes the gap indicator when there are no siblings" do
      table_class.pagination_siblings_count = 0
      visit mocked_table_path(page: 6)
      within ".pagination" do
        %w[First Prev Next Last].each do |link|
          expect(page).to have_link(link)
        end
        %w[2 3 4 5 7 8 9 10].each do |link|
          expect(page).not_to have_link(link)
        end
        expect(page).not_to have_content("…")
      end
    end
  end

  describe "per page select" do
    before { mock_table }

    it "shows the per page select" do
      visit mocked_table_path
      expect(page).to have_select("Per Page", options: %w[25 50 100])
    end
    
    it "updates the per page" do
      visit mocked_table_path
      select "50", from: "Per Page"
      expect_page_to_have_all_records records.first(50)
    end
  end

  def expect_page_to_have_all_records(records)
    records.each do |record|
      expect(page).to have_content(record.name)
    end
  end
end
