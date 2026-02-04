# frozen_string_literal: true

require "test_helper"

module ExportTest
  Record = Struct.new(:id, :name)

  class InstanceTest < ActiveSupport::TestCase
    class TestTable < RapidTable::Base
      include RapidTable::Export

      column :id
      column :name
    end

    def setup
      @records = [
        Record.new(1, "John"),
        Record.new(2, "Jane")
      ]

      @table = TestTable.new(@records)
    end

    test "exports JSON" do
      assert_equal [{ id: 1, name: "John" }, { id: 2, name: "Jane" }], @table.to_json
    end

    test "exports to a CSV stream" do
      assert_equal "id,name\n1,John\n2,Jane\n", @table.stream_csv(StringIO.new).string
    end
  end

  class ClassTest < ActiveSupport::TestCase
    def setup
      @table_class = Class.new RapidTable::Base do
        include RapidTable::Export

        column :id
        column :name

        def id_cell(record, column)
          "ID: #{record.id}."
        end
      end

      @default_json = [{ id: 1, name: "John" }, { id: 2, name: "Jane" }]
      @override_json = [{ id: "ID: 1.", name: "John" }, { id: "ID: 2.", name: "Jane" }]

      @default_csv = "id,name\n1,John\n2,Jane\n"
      @override_csv = "id,name\nID: 1.,John\nID: 2.,Jane\n"
    end

    test "#export_method is used for JSON and CSV export" do
      @table_class.find_column!(:id).export_method = :id_cell

      assert_equal @override_json, table.to_json
      assert_equal @override_csv, table.stream_csv(StringIO.new).string
    end

    test "#json_method is used for JSON export, not CSV" do
      @table_class.find_column!(:id).json_method = :id_cell

      assert_equal @override_json, table.to_json
      assert_equal @default_csv, table.stream_csv(StringIO.new).string
    end

    test "#csv_method is used for CSV export, not JSON" do
      @table_class.find_column!(:id).csv_method = :id_cell

      assert_equal @override_csv, table.stream_csv(StringIO.new).string
      assert_equal @default_json, table.to_json
    end

    test "sugar for specifying column export logic" do
      @table_class.class_eval do
        column :id
        column :name

        column_export :id do |record|
          "ID: #{record.id}."
        end
      end

      assert_equal @override_json, table.to_json
      assert_equal @override_csv, table.stream_csv(StringIO.new).string
    end

    test "sugar for specifying column CSV logic" do
      @table_class.class_eval do
        column :id
        column :name

        column_csv :id do |record|
          "ID: #{record.id}."
        end
      end

      assert_equal @override_csv, table.stream_csv(StringIO.new).string
      assert_equal @default_json, table.to_json
    end

    test "sugar for specifying column JSON logic" do
      @table_class.class_eval do
        column :id
        column :name

        column_json :id do |record|
          "ID: #{record.id}."
        end
      end

      assert_equal @override_json, table.to_json
      assert_equal @default_csv, table.stream_csv(StringIO.new).string
    end

    def table
      @table_class.new([
        Record.new(1, "John"),
        Record.new(2, "Jane")
      ])
    end
  end
end
