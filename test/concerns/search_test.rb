# frozen_string_literal: true

require "test_helper"

module SearchTest
  class InstanceTest < ActiveSupport::TestCase
    class TestTable < RapidTable::Base
      include RapidTable::Search
    end

    # Config options tests
    test "initializes with default values" do
      table = TestTable.new([])
      assert_equal :q, table.search_param
      refute table.skip_search?
    end

    test "allows custom search configuration" do
      table = TestTable.new([], search_param: :search, skip_search: true)
      assert_equal :search, table.search_param
      assert table.skip_search?
    end

    # Search query tests
    test "gets search query from params" do
      table = TestTable.new([])
      table.params[:q] = "john"
      assert_equal "john", table.search_query
    end

    test "returns nil when no search query" do
      table = TestTable.new([])
      assert_nil table.search_query
    end

    # Search functionality tests
    test "requires extension for filtering" do
      table = TestTable.new([])
      assert_raises(RapidTable::ExtensionRequiredError) { table.filter_search(nil) }
    end
  end

  class ClassTest < ActiveSupport::TestCase
    def setup
      @table_class = Class.new RapidTable::Base do
        include RapidTable::Search
      end
    end

    # Class attributes tests
    test "class has default values" do
      refute @table_class.skip_search
      assert_equal :q, @table_class.search_param
    end

    test "allows setting class attributes" do
      @table_class.skip_search = true
      @table_class.search_param = :search

      assert @table_class.skip_search
      assert_equal :search, @table_class.search_param
    end

    # Configuration inheritance tests
    test "inherits class attributes to instance config" do
      @table_class.skip_search = true
      @table_class.search_param = :search

      table = @table_class.new([])
      assert table.skip_search?
      assert_equal :search, table.search_param
    end

    test "allows instance-level overrides" do
      @table_class.skip_search = false
      @table_class.search_param = :q

      table = @table_class.new([],
        skip_search: true,
        search_param: :search
      )
      assert table.skip_search?
      assert_equal :search, table.search_param
    end
  end
end
