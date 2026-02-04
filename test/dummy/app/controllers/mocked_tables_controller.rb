class MockedTablesController < ApplicationController
  include UsesRapidTables
  
  cattr_accessor :table_class
  cattr_accessor :records
  cattr_accessor :options
  cattr_accessor :block

  before_action :set_table

  def show
    respond_to do |format|
      format.html
      format.turbo_stream { replace_table }
      format.csv { rapid_table_csv(@table) }
      format.json { rapid_table_json(@table) }
    end
  end

  def bulk_action
    self.class.perform_bulk_action(params[:bulk_action], params[:ids])

    respond_to do |format|
      format.turbo_stream { replace_table }
      format.html { redirect_to action: "show" }
    end
  end

  private

  def set_table
    @table = self.class.table_class.new(
      self.class.records,
      params:,
      template: view_context,
      **(self.class.options || {}),
      &self.class.block
    )
  end

  def replace_table
    replace_rapid_table(@table, partial: "mocked_tables/table")
  end

  class << self
    def perform_bulk_action(bulk_action, ids)
      raise NotImplementedError
    end
  end
end
