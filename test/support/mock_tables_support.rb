# frozen_string_literal: true

module MockTablesSupport
  extend ActiveSupport::Concern

  included do
    attr_accessor :table_class, :records
  end

  def setup
    super
    @table_class = nil
    @records = []
  end

  def teardown
    MockedTablesController.table_class = nil
    MockedTablesController.records = nil
    MockedTablesController.options = nil
    MockedTablesController.block = nil
    super
  end

  def mock_table(table_class: self.table_class, records: self.records, **options, &block)
    MockedTablesController.table_class = table_class
    MockedTablesController.records = records
    MockedTablesController.options = options
    MockedTablesController.block = block
  end
end
