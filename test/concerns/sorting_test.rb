# frozen_string_literal: true

require "test_helper"

module SortingTest
  class InstanceTest < ActiveSupport::TestCase
    class TestTable < RapidTable::Base
      include RapidTable::Sorting
    end

    attr_reader :sortable_column

    def setup
      @sortable_column = TestTable::Column.new(id: :name, sortable: true, sort_order: "asc")
    end

    # Config options tests
    test "initializes with default values" do
      table = TestTable.new([], columns: [])
      assert_equal :sort, table.sort_column_param
      assert_equal :dir, table.sort_order_param
      refute table.skip_sorting?
    end

    test "allows custom sorting configuration" do
      table = TestTable.new([],
        columns: [],
        sort_column_param: :order_by,
        sort_order_param: :direction,
        skip_sorting: true
      )
      assert_equal :order_by, table.sort_column_param
      assert_equal :direction, table.sort_order_param
      assert table.skip_sorting?
    end

    # Sort parameters tests
    test "gets sort column from params" do
      table = TestTable.new([], columns: [sortable_column])
      table.params[:sort] = "name"
      assert_equal "name", table.sort_column_param_value
    end

    test "gets sort order from params" do
      table = TestTable.new([], columns: [sortable_column])
      table.params[:dir] = "desc"
      assert_equal "desc", table.sort_order_param_value
    end

    test "skips blank sort order params" do
      table = TestTable.new([], columns: [sortable_column])
      table.params[:dir] = ""
      assert_nil table.sort_order_param_value
    end

    test "validates sort order values" do
      table = TestTable.new([], columns: [sortable_column])
      table.params[:dir] = "invalid"
      assert_nil table.sort_order_param_value
    end

    # Sort order utilities tests
    test "reverses sort order" do
      table = TestTable.new([], columns: [sortable_column])
      assert_equal "desc", table.reverse_sort_order("asc")
      assert_equal "asc", table.reverse_sort_order("desc")
    end

    test "provides available sort orders" do
      table = TestTable.new([], columns: [sortable_column])
      assert_equal ["asc", "desc"], table.available_sort_orders
    end

    # Column sorting tests
    test "allows columns to be sortable" do
      column = TestTable::Column.new(id: :email, sortable: true, sort_order: "desc")
      assert column.sortable?
      assert_equal "desc", column.sort_order
    end

    test "requires extension for filtering" do
      table = TestTable.new([], columns: [sortable_column])
      assert_raises(RapidTable::ExtensionRequiredError) { table.filter_sorting(nil) }
    end
  end

  class ClassTest < ActiveSupport::TestCase
    def setup
      @table_class = Class.new RapidTable::Base do
        include RapidTable::Sorting

        column :id
        column :name
        column :email
      end
    end

    # Class attributes tests
    test "class has default values" do
      refute @table_class.skip_sorting
    end

    test "allows setting class attributes" do
      @table_class.skip_sorting = true
      assert @table_class.skip_sorting
    end

    # Sort configuration tests
    test "sets default sort column" do
      @table_class.sort_column = :name

      assert_equal :name, @table_class.sort_column
    end

    test "sets default sort order" do
      @table_class.sort_order = "desc"

      assert_equal "desc", @table_class.sort_order
    end

    test "configures both sort column and order" do
      @table_class.sort_column = :email
      @table_class.sort_order = "asc"

      assert_equal :email, @table_class.sort_column
      assert_equal "asc", @table_class.sort_order
    end

    # Configuration inheritance tests
    test "inherits class attributes to instance config" do
      @table_class.skip_sorting = true
      @table_class.sort_column = :name
      @table_class.sort_order = "desc"

      table = @table_class.new([])
      assert table.skip_sorting?
      assert_equal :name, table.config.sort_column
      assert_equal "desc", table.config.sort_order
    end

    test "allows instance-level overrides" do
      @table_class.skip_sorting = false
      @table_class.sort_column = :id
      @table_class.sort_order = "asc"

      table = @table_class.new([],
        skip_sorting: true,
        column_group_id: :default
      )
      assert table.skip_sorting?
    end

    # Column group integration tests
    test "uses default column group for sort configuration" do
      @table_class.sort_column = :name
      @table_class.sort_order = "desc"

      group = @table_class.find_column_group(:default)
      assert_equal :name, group.sort_column
      assert_equal "desc", group.sort_order
    end
  end
end
