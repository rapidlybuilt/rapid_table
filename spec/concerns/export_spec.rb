# frozen_string_literal: true

require "rails_helper"

RSpec.describe RapidTable::Export do
  let_table_class do
    include RapidTable::Export
  end

  let(:id_column) { column_class.new(id: :id) }
  let(:name_column) { column_class.new(id: :name) }
  let(:email_column) { column_class.new(id: :email) }
  let(:table) { table_class.new([], columns: [id_column, name_column]) }

  describe "config options" do
    it "initializes export with default values" do
      table = table_class.new([], columns: [id_column, name_column])
      expect(table.csv_column_separator).to eq(",")
      expect(table.export_batch_size).to eq(1000)
      expect(table.export_formats).to eq([:csv, :json])
      expect(table.skip_export?).to be false
    end

    it "allows custom export configuration" do
      table = table_class.new([], 
        columns: [id_column, name_column],
        csv_column_separator: ";",
        export_batch_size: 500,
        export_formats: [:csv],
        skip_export: true
      )
      expect(table.csv_column_separator).to eq(";")
      expect(table.export_batch_size).to eq(500)
      expect(table.export_formats).to eq([:csv])
      expect(table.skip_export?).to be true
    end

    it "disables export when no formats specified" do
      table = table_class.new([], columns: [id_column, name_column], export_formats: [])
      expect(table.skip_export?).to be true
    end
  end

  describe "#export_columns" do
    it "returns all columns when none are marked to skip" do
      table = table_class.new([], columns: [id_column, name_column, email_column])
      expect(table.export_columns).to eq([id_column, name_column, email_column])
    end

    it "filters out columns marked to skip export" do
      email_column.skip_export = true
      table = table_class.new([], columns: [id_column, name_column, email_column])
      expect(table.export_columns).to eq([id_column, name_column])
    end
  end

  describe "exporting data" do
    let(:stream) { StringIO.new }
    let(:functional_table) do
      table.instance_eval do
        def each_record(batch_size: nil, skip_pagination: false)
          record = Object.new
          record.define_singleton_method(:id) { 1 }
          record.define_singleton_method(:name) { "John" }
          yield record
        end
      end
      table
    end

    it "knows when it's not exporting data" do
      expect(table.exporting_data?).to be_falsey
    end

    it "requires an extension to export data" do
      expect { table.to_json }.to raise_error(RapidTable::ExtensionRequiredError)
    end

    it "exports JSON" do
      expect(functional_table.to_json).to eq([{id: 1, name: "John"}])
    end

    it "exports to a CSV stream" do
      functional_table.stream_csv(stream)
      expect(stream.string).to eq("id,name\n1,John\n")
    end
  end

  describe "column export options" do
    it "allows columns to be marked for export exclusion" do
      column = column_class.new(id: :secret, skip_export: true)
      expect(column.skip_export?).to be true
    end

    it "provides default export inclusion for columns" do
      column = column_class.new(id: :name)
      expect(column.skip_export?).to be_falsey
    end
  end

  describe "class attributes" do
    it "has default values" do
      expect(table_class.skip_export).to be_falsey
      expect(table_class.csv_column_separator).to eq(",")
      expect(table_class.export_batch_size).to eq(1000)
    end

    it "allows setting class attributes" do
      table_class.skip_export = true
      table_class.csv_column_separator = ";"
      table_class.export_batch_size = 500
      
      expect(table_class.skip_export).to be_truthy
      expect(table_class.csv_column_separator).to eq(";")
      expect(table_class.export_batch_size).to eq(500)
    end
  end

  describe "configuration inheritance" do
    it "inherits class attributes to instance config" do
      table_class.skip_export = true
      table_class.csv_column_separator = ";"
      table_class.export_batch_size = 500
      
      table = table_class.new([], columns: [])
      expect(table.skip_export?).to be_truthy
      expect(table.csv_column_separator).to eq(";")
      expect(table.export_batch_size).to eq(500)
    end

    it "allows instance-level overrides" do
      table_class.skip_export = false
      table_class.csv_column_separator = ","
      table_class.export_batch_size = 1000
      
      table = table_class.new([], 
        columns: [],
        skip_export: true,
        csv_column_separator: ";",
        export_batch_size: 500
      )
      expect(table.skip_export?).to be_truthy
      expect(table.csv_column_separator).to eq(";")
      expect(table.export_batch_size).to eq(500)
    end
  end
end
