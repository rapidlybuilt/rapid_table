# frozen_string_literal: true

require "rails_helper"

RSpec.describe RapidTable::Ext::Pagination do
  let_table_class do
    include RapidTable::Ext::Pagination
  end

  let(:table) { table_class.new([]) }

  describe "config options" do
    it "initializes with default values" do
      table = table_class.new([])
      expect(table.page_param).to eq(:page)
      expect(table.per_page_param).to eq(:per)
      expect(table.available_per_pages).to eq([25, 50, 100])
      expect(table.skip_pagination?).to be_falsey
    end

    it "allows custom pagination configuration" do
      table = table_class.new([],
        page_param: :p,
        per_page_param: :size,
        available_per_pages: [10, 20],
        skip_pagination: true
      )
      expect(table.page_param).to eq(:p)
      expect(table.per_page_param).to eq(:size)
      expect(table.available_per_pages).to eq([10, 20])
      expect(table.skip_pagination?).to be_truthy
    end
  end

  describe "pagination state" do
    it "hides pagination when only one page" do
      table = table_class.new([])
      allow(table).to receive(:total_records_count).and_return(20)
      expect(table.only_ever_one_page?).to be_truthy
    end

    it "requires extension for pagination methods" do
      expect { table.total_records_count }.to raise_error(RapidTable::ExtensionRequiredError)
      expect { table.total_pages }.to raise_error(RapidTable::ExtensionRequiredError)
      expect { table.current_page }.to raise_error(RapidTable::ExtensionRequiredError)
    end
  end

  describe "parameter handling" do
    it "gets per_page from params" do
      table.params[:per] = "50"
      expect(table.per_page_param_value).to eq(50)
    end

    it "gets page from params" do
      table.params[:page] = "2"
      expect(table.page_param_value).to eq("2")
    end
  end

  describe "not implemented methods" do
    %w[total_records_count total_pages current_page].each do |method|
      it "raises an error when #{method} is called" do
        expect { table.send(method) }.to raise_error(RapidTable::ExtensionRequiredError)
      end
    end
  end

  describe "class attributes" do
    it "has default values" do
      expect(table_class.skip_pagination).to be_falsey
      expect(table_class.page_param).to eq(:page)
      expect(table_class.per_page_param).to eq(:per)
    end

    it "allows setting class attributes" do
      table_class.skip_pagination = true
      table_class.page_param = :p
      table_class.per_page_param = :size
      table_class.per_page = 25
      table_class.available_per_pages = [10, 25, 50]

      expect(table_class.skip_pagination).to be_truthy
      expect(table_class.page_param).to eq(:p)
      expect(table_class.per_page_param).to eq(:size)
      expect(table_class.per_page).to eq(25)
      expect(table_class.available_per_pages).to eq([10, 25, 50])
    end
  end

  describe "configuration inheritance" do
    it "inherits class attributes to instance config" do
      table_class.skip_pagination = true
      table_class.page_param = :p
      table_class.per_page_param = :size
      table_class.per_page = 25
      table_class.available_per_pages = [10, 25, 50]

      table = table_class.new([])
      expect(table.skip_pagination?).to be_truthy
      expect(table.page_param).to eq(:p)
      expect(table.per_page_param).to eq(:size)
      expect(table.per_page).to eq(25)
      expect(table.available_per_pages).to eq([10, 25, 50])
    end

    it "allows instance-level overrides" do
      table_class.skip_pagination = false
      table_class.page_param = :page
      table_class.per_page_param = :per
      table_class.per_page = 50
      table_class.available_per_pages = [25, 50, 100]

      table = table_class.new([],
        skip_pagination: true,
        page_param: :p,
        per_page_param: :size,
        per_page: 25,
        available_per_pages: [10, 25, 50]
      )
      expect(table.skip_pagination?).to be_truthy
      expect(table.page_param).to eq(:p)
      expect(table.per_page_param).to eq(:size)
      expect(table.per_page).to eq(25)
      expect(table.available_per_pages).to eq([10, 25, 50])
    end
  end
end
