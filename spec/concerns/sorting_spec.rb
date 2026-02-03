# frozen_string_literal: true

require "rails_helper"

RSpec.describe RapidTable::Sorting do
  let_table_class do
    include RapidTable::Sorting
  end

  let(:sortable_column) { column_class.new(id: :name, sortable: true, sort_order: "asc") }
  let(:table) { table_class.new([], columns: [sortable_column]) }

  describe "config options" do
    it "initializes with default values" do
      table = table_class.new([], columns: [])
      expect(table.sort_column_param).to eq(:sort)
      expect(table.sort_order_param).to eq(:dir)
      expect(table.skip_sorting?).to be_falsey
    end

    it "allows custom sorting configuration" do
      table = table_class.new([],
        columns: [],
        sort_column_param: :order_by,
        sort_order_param: :direction,
        skip_sorting: true
      )
      expect(table.sort_column_param).to eq(:order_by)
      expect(table.sort_order_param).to eq(:direction)
      expect(table.skip_sorting?).to be_truthy
    end
  end

  describe "sort parameters" do
    it "gets sort column from params" do
      table.params[:sort] = "name"
      expect(table.sort_column_param_value).to eq("name")
    end

    it "gets sort order from params" do
      table.params[:dir] = "desc"
      expect(table.sort_order_param_value).to eq("desc")
    end

    it "skips blank sort order params" do
      table.params[:dir] = ""
      expect(table.sort_order_param_value).to be_nil
    end

    it "validates sort order values" do
      table.params[:dir] = "invalid"
      expect(table.sort_order_param_value).to be_nil
    end
  end

  describe "sort order utilities" do
    it "reverses sort order" do
      expect(table.reverse_sort_order("asc")).to eq("desc")
      expect(table.reverse_sort_order("desc")).to eq("asc")
    end

    it "provides available sort orders" do
      expect(table.available_sort_orders).to eq(["asc", "desc"])
    end
  end

  describe "column sorting" do
    it "allows columns to be sortable" do
      column = column_class.new(id: :email, sortable: true, sort_order: "desc")
      expect(column.sortable?).to be_truthy
      expect(column.sort_order).to eq("desc")
    end

    it "requires extension for filtering" do
      expect { table.filter_sorting(nil) }.to raise_error(RapidTable::ExtensionRequiredError)
    end
  end

  describe "class methods" do

    describe "class attributes" do
      it "has default values" do
        expect(table_class.skip_sorting).to be_falsey
      end

      it "allows setting class attributes" do
        table_class.skip_sorting = true
        expect(table_class.skip_sorting).to be_truthy
      end
    end

    describe "sort configuration" do
      before do
        table_class.column :id
        table_class.column :name
        table_class.column :email
      end

      it "sets default sort column" do
        table_class.sort_column = :name
        expect(table_class.sort_column).to eq(:name)
      end

      it "sets default sort order" do
        table_class.sort_order = "desc"
        expect(table_class.sort_order).to eq("desc")
      end

      it "configures both sort column and order" do
        table_class.sort_column = :email
        table_class.sort_order = "asc"

        expect(table_class.sort_column).to eq(:email)
        expect(table_class.sort_order).to eq("asc")
      end
    end

    describe "configuration inheritance" do
      before do
        table_class.column :id
        table_class.column :name
      end

      it "inherits class attributes to instance config" do
        table_class.skip_sorting = true
        table_class.sort_column = :name
        table_class.sort_order = "desc"

        table = table_class.new([])
        expect(table.skip_sorting?).to be_truthy
        expect(table.config.sort_column).to eq(:name)
        expect(table.config.sort_order).to eq("desc")
      end

      it "allows instance-level overrides" do
        table_class.skip_sorting = false
        table_class.sort_column = :id
        table_class.sort_order = "asc"

        table = table_class.new([],
          skip_sorting: true,
          column_group_id: :default
        )
        expect(table.skip_sorting?).to be_truthy
      end
    end

    describe "column group integration" do
      it "uses default column group for sort configuration" do
        table_class.column :id
        table_class.column :name

        table_class.sort_column = :name
        table_class.sort_order = "desc"

        group = table_class.find_column_group(:default)
        expect(group.sort_column).to eq(:name)
        expect(group.sort_order).to eq("desc")
      end
    end
  end
end
