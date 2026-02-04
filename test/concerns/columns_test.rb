# frozen_string_literal: true

require "test_helper"

module ColumnsTest
  class InstanceTest < ActiveSupport::TestCase
    class TestTable < RapidTable::Base
      include RapidTable::Columns
    end

    attr_reader :id_column
    attr_reader :name_column
    attr_reader :email_column

    def setup
      super

      @id_column = TestTable::Column.new(id: :id)
      @name_column = TestTable::Column.new(id: :name)
      @email_column = TestTable::Column.new(id: :email)
    end

    # Config options tests
    test "initializes columns" do
      table = TestTable.new([], columns: [id_column, name_column])
      assert_equal [id_column, name_column], table.columns
    end

    test "builds column classes when given an array of hashes" do
      table = TestTable.new([], columns: [{ id: :id }, { id: :name }])
      assert_equal [TestTable::Column, TestTable::Column], table.columns.map(&:class)
      assert_equal [:id, :name], table.columns.map(&:id)
    end

    test "raises error when no columns specified" do
      error = assert_raises(ArgumentError) { TestTable.new([]) }
      assert_equal "columns must be specified", error.message
    end

    test "filters out certain columns with the except option" do
      table = TestTable.new([], columns: [id_column, name_column, email_column], except: :email)
      assert_equal [id_column, name_column], table.columns
    end

    test "keeps only certain columns with the only option" do
      table = TestTable.new([], columns: [id_column, name_column, email_column], only: [:id, :email])
      assert_equal [id_column, email_column], table.columns
    end

    # column_label tests
    test "column_label renders column label" do
      table = TestTable.new([], columns: [id_column, name_column])
      column = TestTable::Column.new(id: :name, label: "Full Name")
      result = table.column_label(column)
      assert_includes result, "Full Name"
    end

    test "column_label uses titleized id when no label provided" do
      table = TestTable.new([], columns: [id_column, name_column])
      column = TestTable::Column.new(id: :user_name)
      result = table.column_label(column)
      assert_includes result, "User Name"
    end

    # column_cell tests
    test "column_cell renders cell content from record attribute" do
      table = TestTable.new([], columns: [id_column, name_column])
      record = Minitest::Mock.new
      record.expect(:name, "John Doe")

      column = TestTable::Column.new(id: :name)
      result = table.column_cell(record, column)
      assert_equal "John Doe", result
    end

    test "column_cell renders cell content based on its type" do
      table = TestTable.new([], columns: [id_column, name_column])
      record = Minitest::Mock.new
      record.expect(:name, "John Doe")

      column = TestTable::Column.new(id: :name)

      table.instance_eval do
        def string_cell(record)
          "STRING"
        end
      end

      result = table.column_cell(record, column)
      assert_equal "STRING", result
    end

    test "column_cell uses custom cell method before falling back to the type" do
      column = TestTable::Column.new(id: :email, cell_method: :formatted_email)
      table = TestTable.new([], columns: [column])
      record = Minitest::Mock.new

      table.instance_eval do
        def formatted_email(record)
          "FORMATTED"
        end

        def string_cell(record)
          "STRING"
        end
      end

      result = table.column_cell(record, column)
      assert_equal "FORMATTED", result
    end
  end

  class ClassTest < ActiveSupport::TestCase
    def setup
      @table_class = Class.new RapidTable::Base do
        include RapidTable::Columns
      end
    end

    # Class methods - column definitions tests
    test "defines columns with basic options" do
      @table_class.column :id, label: "ID"
      @table_class.column :name, label: "Full Name"

      assert_equal [:id, :name], @table_class.columns.map(&:id)
      assert_equal ["ID", "Full Name"], @table_class.columns.map(&:label)
    end

    test "finds columns by id" do
      @table_class.column :email
      column = @table_class.find_column(:email)
      assert_equal :email, column.id
    end

    test "raises error when column not found" do
      assert_raises(RapidTable::Columns::ColumnNotFoundError) { @table_class.find_column!(:missing) }
    end

    # Class methods - column groups tests
    test "defines column groups" do
      @table_class.column :id
      @table_class.column :name
      @table_class.column :email
      @table_class.column_group :basic, [:name, :email]

      group = @table_class.find_column_group(:basic)
      assert_equal :basic, group.id
      assert_equal [:name, :email], group.column_ids
    end

    test "finds column groups by id" do
      @table_class.column :id
      @table_class.column :name
      @table_class.column :email
      @table_class.column_group :basic, [:name, :email]

      group = @table_class.find_column_group!(:basic)
      assert_equal :basic, group.id
    end

    test "raises error when column group not found" do
      assert_raises(RapidTable::Columns::ColumnGroupNotFoundError) { @table_class.find_column_group!(:missing) }
    end

    # Finding columns tests
    test "finds columns by ids" do
      @table_class.column :id
      @table_class.column :name
      @table_class.column_group :basic, [:id, :name]

      columns = @table_class.find_columns!(column_ids: [:id, :name])
      assert_equal [:id, :name], columns.map(&:id)
    end

    test "finds columns by group id" do
      @table_class.column :id
      @table_class.column :name
      @table_class.column_group :basic, [:id, :name]

      columns = @table_class.find_columns!(column_group_id: :basic)
      assert_equal [:id, :name], columns.map(&:id)
    end

    test "raises error when both column ids and group specified" do
      @table_class.column :id
      @table_class.column :name
      @table_class.column_group :basic, [:id, :name]

      error = assert_raises(ArgumentError) { @table_class.find_columns!(column_ids: [:id], column_group_id: :basic) }
      assert_equal "column_ids and column_group_id cannot be used together", error.message
    end

    test "raises error when neither column ids nor group specified" do
      error = assert_raises(ArgumentError) { @table_class.find_columns! }
      assert_equal "column_ids or column_group_id must be specified", error.message
    end

    # Inheritance tests
    test "inherits columns from parent" do
      parent_class = Class.new do
        include RapidTable::Support
        include RapidTable::Columns
        column :id
        column :name
        column_group :basic, [:name]
      end

      child_class = Class.new(parent_class) do
        column :email
      end

      assert_equal [:id, :name, :email], child_class.columns.map(&:id)
    end

    test "inherits column groups from parent" do
      parent_class = Class.new do
        include RapidTable::Support
        include RapidTable::Columns
        column :id
        column :name
        column_group :basic, [:name]
      end

      child_class = Class.new(parent_class) do
        column :email
      end

      assert_equal [:basic], child_class.column_groups.map(&:id)
    end

    test "finds parent columns in child class" do
      parent_class = Class.new do
        include RapidTable::Support
        include RapidTable::Columns
        column :id
        column :name
        column_group :basic, [:name]
      end

      child_class = Class.new(parent_class) do
        column :email
      end

      column = child_class.find_column(:id)
      assert_equal :id, column.id
    end
  end
end
