require "sandbox_helper"

RSpec.describe "Columns", type: :system do
  let_table_class superclass: ApplicationTable do
    include RapidTable::Columns
    include RapidTable::Ext::Array

    column :id
    column :name
  end

  let(:record_class) { Struct.new(:id, :name) }
  let(:records) { (1..50).map { |i| record_class.new(i, "Name #{i}.") } }

  describe "labels" do
    before { mock_table }

    it "tries an explicit label first" do
      table_class.find_column(:id).label = "Identifier"
      visit mocked_table_path
      expect(page).not_to have_content("ID")
      expect(page).to have_content("Identifier")
    end

    it "then tries I18n" do
      mock_translation "rapid_table.test_table.columns.id", "Identifier"
      visit mocked_table_path
      expect(page).not_to have_content("ID")
      expect(page).to have_content("Identifier")
    end

    it "then tries #titleize" do
      visit mocked_table_path
      expect(page).to have_content("Id")
    end
  end

  describe "cell rendering" do
    before { mock_table }

    it "allows explicit column cell methods" do
      table_class.class_eval do
        def id_cell(record)
          "ID: #{record.id}."
        end
      end

      visit mocked_table_path
      expect(page).to have_content("ID: 1.")
      expect(page).to have_content("ID: 2.")
    end

    it "allows explicit column type methods" do
      table_class.class_eval do
        def string_cell(value)
          "String: #{value}."
        end
      end

      visit mocked_table_path
      expect(page).to have_content("String: Name 1..")
      expect(page).to have_content("String: Name 2..")
    end
  end

  describe "filtering" do
    it "allows showing only certain columns" do
      mock_table only: [:id]
      visit mocked_table_path
      expect(page).to have_content("Id")
      expect(page).not_to have_content("Name")
    end

    it "allows showing all except certain columns" do
      mock_table except: [:name]
      visit mocked_table_path
      expect(page).to have_content("Id")
      expect(page).not_to have_content("Name")
    end
  end
end
