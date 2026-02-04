# frozen_string_literal: true

require "test_helper"

module PaginationTest
  class InstanceTest < ActiveSupport::TestCase
    class TestTable < RapidTable::Base
      include RapidTable::Ext::Pagination
    end

    test "initializes with default values" do
      table = TestTable.new([])
      assert_equal :page, table.page_param
      assert_equal :per, table.per_page_param
      assert_equal [25, 50, 100], table.available_per_pages
      refute table.skip_pagination?
    end

    test "allows custom pagination configuration" do
      table = TestTable.new([],
        page_param: :p,
        per_page_param: :size,
        available_per_pages: [10, 20],
        skip_pagination: true
      )
      assert_equal :p, table.page_param
      assert_equal :size, table.per_page_param
      assert_equal [10, 20], table.available_per_pages
      assert table.skip_pagination?
    end

    # Pagination state tests
    test "hides pagination when only one page" do
      table = TestTable.new([])
      table.stub(:total_records_count, 20) do
        assert table.only_ever_one_page?
      end
    end

    test "requires extension for pagination methods" do
      table = TestTable.new([])
      assert_raises(RapidTable::ExtensionRequiredError) { table.total_records_count }
      assert_raises(RapidTable::ExtensionRequiredError) { table.total_pages }
      assert_raises(RapidTable::ExtensionRequiredError) { table.current_page }
    end

    # Parameter handling tests
    test "gets per_page from params" do
      table = TestTable.new([])
      table.params[:per] = "50"
      assert_equal 50, table.per_page_param_value
    end

    test "gets page from params" do
      table = TestTable.new([])
      table.params[:page] = "2"
      assert_equal "2", table.page_param_value
    end
  end

  class ClassTest < ActiveSupport::TestCase
    def setup
      @table_class = Class.new RapidTable::Base do
        include RapidTable::Ext::Pagination
      end
    end

    test "class has default values" do
      refute @table_class.skip_pagination
      assert_equal :page, @table_class.page_param
      assert_equal :per, @table_class.per_page_param
    end

    test "allows setting class attributes" do
      @table_class.skip_pagination = true
      @table_class.page_param = :p
      @table_class.per_page_param = :size
      @table_class.per_page = 25
      @table_class.available_per_pages = [10, 25, 50]

      assert @table_class.skip_pagination
      assert_equal :p, @table_class.page_param
      assert_equal :size, @table_class.per_page_param
      assert_equal 25, @table_class.per_page
      assert_equal [10, 25, 50], @table_class.available_per_pages
    end

    # Configuration inheritance tests
    test "inherits class attributes to instance config" do
      @table_class.skip_pagination = true
      @table_class.page_param = :p
      @table_class.per_page_param = :size
      @table_class.per_page = 25
      @table_class.available_per_pages = [10, 25, 50]

      table = @table_class.new([])
      assert table.skip_pagination?
      assert_equal :p, table.page_param
      assert_equal :size, table.per_page_param
      assert_equal 25, table.per_page
      assert_equal [10, 25, 50], table.available_per_pages
    end

    test "allows instance-level overrides" do
      @table_class.skip_pagination = false
      @table_class.page_param = :page
      @table_class.per_page_param = :per
      @table_class.per_page = 50
      @table_class.available_per_pages = [25, 50, 100]

      table = @table_class.new([],
        skip_pagination: true,
        page_param: :p,
        per_page_param: :size,
        per_page: 25,
        available_per_pages: [10, 25, 50]
      )
      assert table.skip_pagination?
      assert_equal :p, table.page_param
      assert_equal :size, table.per_page_param
      assert_equal 25, table.per_page
      assert_equal [10, 25, 50], table.available_per_pages
    end
  end
end
