# frozen_string_literal: true

require "test_helper"

module BulkActionsTest
  class InstanceTest < ActiveSupport::TestCase
    class TestTable < RapidTable::Base
      include RapidTable::Ext::BulkActions
    end

    attr_reader :bulk_action

    def setup
      @bulk_action = TestTable::BulkAction.new(id: :delete, label: "Delete Selected")
    end

    # Config options tests
    test "initializes with default values" do
      table = TestTable.new([])
      assert_equal :ids, table.bulk_actions_param
      assert table.skip_bulk_actions?
    end

    test "enables bulk actions when actions are provided" do
      table = TestTable.new([], bulk_actions: [bulk_action])
      refute table.skip_bulk_actions?
    end

    # Bulk action class tests
    test "bulk action has accessible attributes" do
      action = TestTable::BulkAction.new(id: :archive, label: "Archive")
      assert_equal :archive, action.id
      assert_equal "Archive", action.label
    end

    # Record selection tests
    test "gets selected record IDs from params" do
      table = TestTable.new([], bulk_actions: [bulk_action])
      table.stub(:full_params, { ids: ["1", "2"] }) do
        assert_equal ["1", "2"], table.selected_bulk_action_record_ids
      end
    end

    test "checks if record is selected" do
      table = TestTable.new([], bulk_actions: [bulk_action])
      record = Object.new

      table.stub(:full_params, { ids: ["1"] }) do
        table.stub(:record_id, "1") do
          assert table.selected_bulk_action_record?(record)
        end
      end
    end

    # Bulk action labels tests
    test "uses explicit label" do
      table = TestTable.new([], bulk_actions: [bulk_action])
      assert_equal "Delete Selected", table.bulk_action_label(bulk_action)
    end

    test "falls back to titleized id" do
      table = TestTable.new([], bulk_actions: [bulk_action])
      action = TestTable::BulkAction.new(id: :archive_selected)
      assert_equal "Archive Selected", table.bulk_action_label(action)
    end
  end

  class ClassTest < ActiveSupport::TestCase
    def setup
      @table_class = Class.new RapidTable::Base do
        include RapidTable::Ext::BulkActions
      end
    end

    test "class has default values" do
      refute @table_class.skip_bulk_actions
      assert_equal :ids, @table_class.bulk_actions_param
    end

    test "allows setting class attributes" do
      @table_class.skip_bulk_actions = true
      @table_class.bulk_actions_param = :selected

      assert @table_class.skip_bulk_actions
      assert_equal :selected, @table_class.bulk_actions_param
    end

    # Bulk action definitions tests
    test "defines bulk actions" do
      @table_class.bulk_action :delete, label: "Delete Selected"
      @table_class.bulk_action :archive, label: "Archive Selected"

      assert_equal [:delete, :archive], @table_class.bulk_actions.map(&:id)
      assert_equal ["Delete Selected", "Archive Selected"], @table_class.bulk_actions.map(&:label)

      table = @table_class.new([])
      assert_equal [:delete, :archive], table.bulk_actions.map(&:id)
      assert_equal ["Delete Selected", "Archive Selected"], table.bulk_actions.map(&:label)
    end

    test "finds bulk actions by id" do
      @table_class.bulk_action :delete, label: "Delete"
      action = @table_class.find_bulk_action(:delete)
      assert_equal :delete, action.id
      assert_equal "Delete", action.label
    end

    test "raises error when bulk action not found" do
      assert_raises(RapidTable::Ext::BulkActions::BulkActionNotFoundError) { @table_class.find_bulk_action(:missing) }
    end

    # Inheritance tests
    test "inherits bulk actions from parent" do
      parent_class = Class.new do
        include RapidTable::Support
        include RapidTable::Ext::BulkActions
        bulk_action :delete
      end

      child_class = Class.new(parent_class) do
        bulk_action :archive
      end

      assert_equal [:delete, :archive], child_class.bulk_actions.map(&:id)
    end

    test "finds parent bulk actions in child class" do
      parent_class = Class.new do
        include RapidTable::Support
        include RapidTable::Ext::BulkActions
        bulk_action :delete
      end

      child_class = Class.new(parent_class) do
        bulk_action :archive
      end

      action = child_class.find_bulk_action(:delete)
      assert_equal :delete, action.id
    end
  end
end
