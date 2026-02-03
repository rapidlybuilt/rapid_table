# frozen_string_literal: true

require "rails_helper"

RSpec.describe RapidTable::BulkActions do
  let_table_class do
    include RapidTable::BulkActions
  end

  let(:bulk_action_class) { table_class.bulk_action_class }
  let(:bulk_action) { bulk_action_class.new(id: :delete, label: "Delete Selected") }
  let(:table) { table_class.new([], bulk_actions: [bulk_action]) }

  describe "config options" do
    it "initializes with default values" do
      table = table_class.new([])
      expect(table.bulk_actions_param).to eq(:ids)
      expect(table.skip_bulk_actions?).to be_truthy
    end

    it "enables bulk actions when actions are provided" do
      table = table_class.new([], bulk_actions: [bulk_action])
      expect(table.skip_bulk_actions?).to be_falsey
    end
  end

  describe "bulk action class" do
    it "has accessible attributes" do
      action = bulk_action_class.new(id: :archive, label: "Archive")
      expect(action.id).to eq(:archive)
      expect(action.label).to eq("Archive")
    end
  end

  describe "record selection" do
    let(:record) { double("record") }

    it "gets selected record IDs from params" do
      allow(table).to receive(:full_params).and_return({ids: ["1", "2"]})
      expect(table.selected_bulk_action_record_ids).to eq(["1", "2"])
    end

    it "checks if record is selected" do
      allow(table).to receive(:full_params).and_return({ids: ["1"]})
      allow(table).to receive(:record_id).with(record).and_return("1")
      expect(table.selected_bulk_action_record?(record)).to be_truthy
    end
  end

  describe "bulk action labels" do
    it "uses explicit label" do
      expect(table.bulk_action_label(bulk_action)).to eq("Delete Selected")
    end

    it "falls back to titleized id" do
      action = bulk_action_class.new(id: :archive_selected)
      expect(table.bulk_action_label(action)).to eq("Archive Selected")
    end
  end

  describe "class attributes" do
    it "has default values" do
      expect(table_class.skip_bulk_actions).to be_falsey
      expect(table_class.bulk_actions_param).to eq(:ids)
    end

    it "allows setting class attributes" do
      table_class.skip_bulk_actions = true
      table_class.bulk_actions_param = :selected

      expect(table_class.skip_bulk_actions).to be_truthy
      expect(table_class.bulk_actions_param).to eq(:selected)
    end
  end

  describe "bulk action definitions" do
    it "defines bulk actions" do
      table_class.bulk_action :delete, label: "Delete Selected"
      table_class.bulk_action :archive, label: "Archive Selected"

      expect(table_class.bulk_actions.map(&:id)).to eq([:delete, :archive])
      expect(table_class.bulk_actions.map(&:label)).to eq(["Delete Selected", "Archive Selected"])

      table = table_class.new([])
      expect(table.bulk_actions.map(&:id)).to eq([:delete, :archive])
      expect(table.bulk_actions.map(&:label)).to eq(["Delete Selected", "Archive Selected"])
    end

    it "finds bulk actions by id" do
      table_class.bulk_action :delete, label: "Delete"
      action = table_class.find_bulk_action(:delete)
      expect(action.id).to eq(:delete)
      expect(action.label).to eq("Delete")
    end

    it "raises error when bulk action not found" do
      expect { table_class.find_bulk_action(:missing) }.to raise_error(RapidTable::BulkActions::NotFoundError)
    end
  end

  describe "inheritance" do
    let(:parent_class) do
      Class.new do
        include RapidTable::Support
        include RapidTable::BulkActions
        bulk_action :delete
      end
    end

    let(:child_class) do
      Class.new(parent_class) do
        bulk_action :archive
      end
    end

    it "inherits bulk actions from parent" do
      expect(child_class.bulk_actions.map(&:id)).to eq([:delete, :archive])
    end

    it "finds parent bulk actions" do
      action = child_class.find_bulk_action(:delete)
      expect(action.id).to eq(:delete)
    end
  end
end
