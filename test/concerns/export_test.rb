# frozen_string_literal: true

require "test_helper"

module ExportTest
  class InstanceTest < ActiveSupport::TestCase
    class TestTable < RapidTable::Base
      include RapidTable::Export
    end

    attr_reader :id_column
    attr_reader :name_column
    attr_reader :email_column

    def setup
      @id_column = TestTable::Column.new(id: :id)
      @name_column = TestTable::Column.new(id: :name)
      @email_column = TestTable::Column.new(id: :email)
    end

    # Config options tests
    test "initializes export with default values" do
      table = TestTable.new([], columns: [id_column, name_column])
      assert_equal ",", table.csv_column_separator
      assert_equal 1000, table.export_batch_size
      assert_equal [:csv, :json], table.export_formats
      refute table.skip_export?
    end

    test "allows custom export configuration" do
      table = TestTable.new([],
        columns: [id_column, name_column],
        csv_column_separator: ";",
        export_batch_size: 500,
        export_formats: [:csv],
        skip_export: true
      )
      assert_equal ";", table.csv_column_separator
      assert_equal 500, table.export_batch_size
      assert_equal [:csv], table.export_formats
      assert table.skip_export?
    end

    test "disables export when no formats specified" do
      table = TestTable.new([], columns: [id_column, name_column], export_formats: [])
      assert table.skip_export?
    end

    # Export columns tests
    test "export_columns returns all columns when none are marked to skip" do
      table = TestTable.new([], columns: [id_column, name_column, email_column])
      assert_equal [id_column, name_column, email_column], table.export_columns
    end

    test "export_columns filters out columns marked to skip export" do
      email_column.skip_export = true
      table = TestTable.new([], columns: [id_column, name_column, email_column])
      assert_equal [id_column, name_column], table.export_columns
    end

    # Exporting data tests
    test "knows when it's not exporting data" do
      table = TestTable.new([], columns: [id_column, name_column])
      refute table.exporting_data?
    end

    test "requires an extension to export data" do
      table = TestTable.new([], columns: [id_column, name_column])
      assert_raises(RapidTable::ExtensionRequiredError) { table.to_json }
    end

    test "exports JSON" do
      table = TestTable.new([], columns: [id_column, name_column])
      table.instance_eval do
        def each_record(batch_size: nil)
          record = Object.new
          record.define_singleton_method(:id) { 1 }
          record.define_singleton_method(:name) { "John" }
          yield record
        end
      end

      assert_equal [{ id: 1, name: "John" }], table.to_json
    end

    test "exports to a CSV stream" do
      table = TestTable.new([], columns: [id_column, name_column])
      table.instance_eval do
        def each_record(batch_size: nil)
          record = Object.new
          record.define_singleton_method(:id) { 1 }
          record.define_singleton_method(:name) { "John" }
          yield record
        end
      end

      stream = StringIO.new
      table.stream_csv(stream)
      assert_equal "id,name\n1,John\n", stream.string
    end

    # Column export options tests
    test "allows columns to be marked for export exclusion" do
      column = TestTable::Column.new(id: :secret, skip_export: true)
      assert column.skip_export?
    end

    test "provides default export inclusion for columns" do
      column = TestTable::Column.new(id: :name)
      refute column.skip_export?
    end
  end

  class ClassTest < ActiveSupport::TestCase
    def setup
      @table_class = Class.new RapidTable::Base do
        include RapidTable::Export
      end
    end

    # Class attributes tests
    test "class has default values" do
      refute @table_class.skip_export
      assert_equal ",", @table_class.csv_column_separator
      assert_equal 1000, @table_class.export_batch_size
    end

    test "allows setting class attributes" do
      @table_class.skip_export = true
      @table_class.csv_column_separator = ";"
      @table_class.export_batch_size = 500

      assert @table_class.skip_export
      assert_equal ";", @table_class.csv_column_separator
      assert_equal 500, @table_class.export_batch_size
    end

    # Configuration inheritance tests
    test "inherits class attributes to instance config" do
      @table_class.skip_export = true
      @table_class.csv_column_separator = ";"
      @table_class.export_batch_size = 500

      table = @table_class.new([], columns: [])
      assert table.skip_export?
      assert_equal ";", table.csv_column_separator
      assert_equal 500, table.export_batch_size
    end

    test "allows instance-level overrides" do
      @table_class.skip_export = false
      @table_class.csv_column_separator = ","
      @table_class.export_batch_size = 1000

      table = @table_class.new([],
        columns: [],
        skip_export: true,
        csv_column_separator: ";",
        export_batch_size: 500
      )
      assert table.skip_export?
      assert_equal ";", table.csv_column_separator
      assert_equal 500, table.export_batch_size
    end
  end
end
