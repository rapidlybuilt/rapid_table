# frozen_string_literal: true

require "rails_helper"

RSpec.describe RapidTable::Columns do
  let_table_class do
    include RapidTable::Columns
  end

  let(:id_column) { column_class.new(id: :id) }
  let(:name_column) { column_class.new(id: :name) }
  let(:email_column) { column_class.new(id: :email) }
  let(:table) { table_class.new([], columns: [id_column, name_column]) }

  describe "config options" do
    it "initializes columns" do
      table = table_class.new([], columns: [id_column, name_column])
      expect(table.columns).to eq([id_column, name_column])
    end

    it "builds column classes when given an array of hashes" do
      table = table_class.new([], columns: [{id: :id}, {id: :name}])
      expect(table.columns.map(&:class)).to eq([column_class, column_class])
      expect(table.columns.map(&:id)).to eq([:id, :name])
    end

    it "raises error when no columns specified" do
      expect { table_class.new([]) }.to raise_error(ArgumentError, "columns must be specified")
    end

    it "filters out certain columns with the except option" do
      table = table_class.new([], columns: [id_column, name_column, email_column], except: :email)
      expect(table.columns).to eq([id_column, name_column])
    end

    it "keeps only certain columns with the only option" do
      table = table_class.new([], columns: [id_column, name_column, email_column], only: [:id, :email])
      expect(table.columns).to eq([id_column, email_column])
    end
  end

  describe "#column_label" do
    it "renders column label" do
      column = column_class.new(id: :name, label: "Full Name")
      result = table.column_label(column)
      expect(result).to include("Full Name")
    end

    it "uses titleized id when no label provided" do
      column = column_class.new(id: :user_name)
      result = table.column_label(column)
      expect(result).to include("User Name")
    end
  end

  describe "#column_cell" do
    let(:record) { double("record", id: 1, name: "John Doe") }

    it "renders cell content from record attribute" do
      column = column_class.new(id: :name)
      result = table.column_cell(record, column)
      expect(result).to eq("John Doe")
    end

    it "renders cell content based on its type" do
      column = column_class.new(id: :name)

      table.instance_eval do
        def string_cell(record)
          "STRING"
        end
      end

      result = table.column_cell(record, column)
      expect(result).to eq("STRING")
    end

    it "uses custom cell method before falling back to the type" do
      column = column_class.new(id: :email, cell_method: :formatted_email)
      table = table_class.new([], columns: [column])

      table.instance_eval do
        def formatted_email(record)
          "FORMATTED"
        end

        def string_cell(record)
          "STRING"
        end
      end

      result = table.column_cell(record, column)
      expect(result).to eq("FORMATTED")
    end
  end

  describe "class methods" do
    describe "column definitions" do
      it "defines columns with basic options" do
        table_class.column :id, label: "ID"
        table_class.column :name, label: "Full Name"

        expect(table_class.columns.map(&:id)).to eq([:id, :name])
        expect(table_class.columns.map(&:label)).to eq(["ID", "Full Name"])
      end

      it "finds columns by id" do
        table_class.column :email
        column = table_class.find_column(:email)
        expect(column.id).to eq(:email)
      end

      it "raises error when column not found" do
        expect { table_class.find_column!(:missing) }.to raise_error(RapidTable::Columns::ColumnNotFoundError)
      end
    end

    describe "column groups" do
      before do
        table_class.column :id
        table_class.column :name
        table_class.column :email
      end

      it "defines column groups" do
        table_class.column_group :basic, [:name, :email]
        group = table_class.find_column_group(:basic)
        expect(group.id).to eq(:basic)
        expect(group.column_ids).to eq([:name, :email])
      end

      it "finds column groups by id" do
        table_class.column_group :basic, [:name, :email]
        group = table_class.find_column_group!(:basic)
        expect(group.id).to eq(:basic)
      end

      it "raises error when column group not found" do
        expect { table_class.find_column_group!(:missing) }.to raise_error(RapidTable::Columns::ColumnGroupNotFoundError)
      end
    end

    describe "finding columns" do
      before do
        table_class.column :id
        table_class.column :name
        table_class.column_group :basic, [:id, :name]
      end

      it "finds columns by ids" do
        columns = table_class.find_columns!(column_ids: [:id, :name])
        expect(columns.map(&:id)).to eq([:id, :name])
      end

      it "finds columns by group id" do
        columns = table_class.find_columns!(column_group_id: :basic)
        expect(columns.map(&:id)).to eq([:id, :name])
      end

      it "raises error when both ids and group specified" do
        expect { table_class.find_columns!(column_ids: [:id], column_group_id: :basic) }
          .to raise_error(ArgumentError, "column_ids and column_group_id cannot be used together")
      end

      it "raises error when neither specified" do
        expect { table_class.find_columns! }
          .to raise_error(ArgumentError, "column_ids or column_group_id must be specified")
      end
    end

    describe "inheritance" do
      let(:parent_class) do
        Class.new do
          include RapidTable::Support
          include RapidTable::Columns
          column :id
          column :name

          column_group :basic, [:name]
        end
      end

      let(:child_class) do
        Class.new(parent_class) do
          column :email
        end
      end

      it "inherits columns from parent" do
        expect(child_class.columns.map(&:id)).to eq([:id, :name, :email])
      end

      it "inherits column groups from parent" do
        expect(child_class.column_groups.map(&:id)).to eq([:basic])
      end

      it "finds parent columns" do
        column = child_class.find_column(:id)
        expect(column.id).to eq(:id)
      end
    end
  end
end
