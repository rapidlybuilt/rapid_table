# frozen_string_literal: true

module RapidTable
  # The Export module provides functionality for exporting table data in various formats
  # in RapidTable. It exposes the following configuration options to RapidTable::Base:
  #
  # @option config csv_column_separator [String] The separator to use for CSV exports (default: ",")
  # @option config export_batch_size [Integer] The number of records to process in each batch (default: 1000)
  # @option config export_formats [Array<Symbol>] The formats available for export (default: [:csv, :json])
  # @option config skip_export [Boolean] Whether to skip export functionality entirely
  #
  # Column-level export options:
  # @option config column.skip_export [Boolean] Whether to exclude this column from exports
  #
  # @example Basic usage
  #   class MyTable < RapidTable::Base
  #     self.skip_export = false
  #     self.csv_column_separator = ";"
  #     self.export_batch_size = 500
  #   end
  #
  # @example With export disabled
  #   class MyTable < RapidTable::Base
  #     self.skip_export = true
  #   end
  module Export
    extend ActiveSupport::Concern

    included do
      include Columns

      config_attribute :skip_export, default: false
      config_attribute :csv_column_separator, default: ","
      config_attribute :export_batch_size, default: 1000
      config_attribute :export_formats, default: %i[csv json]

      register_initializer :export

      column_class! do
        attr_accessor :skip_export
        alias_method :skip_export?, :skip_export

        attr_accessor :export_method
        attr_accessor :csv_method
        attr_accessor :json_method
      end
    end

    # Returns columns that should be included in exports, filtering out those marked as skip_export.
    #
    # @return [Array<Column>] The columns to include in exports
    def export_columns
      columns.clone.reject(&:skip_export?)
    end

    # Streams CSV data to the provided stream object.
    #
    # @param stream [IO] The stream to write CSV data to
    # @return [void]
    def stream_csv(stream)
      require "csv"

      row_sep = "\n"

      stream.write(CSV.generate_line(export_columns.map(&:id), row_sep:))

      each_record(batch_size: export_batch_size) do |record|
        cells = export_columns.map do |column|
          column_cell_csv(record, column)
        end

        stream.write(CSV.generate_line(cells, row_sep:))
      end

      stream
    end

    # Exports table data as JSON.
    #
    # @return [Array<Hash>] Array of hashes representing table records
    def to_json(*_args)
      data = []

      each_record(batch_size: export_batch_size) do |record|
        data << export_columns.each_with_object({}) do |column, hash|
          hash[column.id] = column_cell_json(record, column)
        end
      end

      data
    end

    # Returns the cell value formatted for CSV export.
    #
    # @param record [Object] The record object to render the cell for
    # @param column [Object] The column object defining how to render the cell
    # @return [Object] The cell value for CSV
    def column_cell_csv(record, column)
      csv_method = column.csv_method || column.export_method || column.value_method || :column_cell_value
      send(csv_method, record, column)
    end

    # Returns the cell value formatted for JSON export.
    #
    # @param record [Object] The record object to render the cell for
    # @param column [Object] The column object defining how to render the cell
    # @return [Object] The cell value for JSON
    def column_cell_json(record, column)
      json_method = column.json_method || column.export_method || column.value_method || :column_cell_value
      send(json_method, record, column)
    end

    # rubocop:disable Lint/UnusedMethodArgument

    # Iterates over records for export processing.
    # By default, yields each record in turn.
    # Extensions may override for optimal batch or paged access.
    #
    # @param batch_size [Integer, nil] The number of records to process in each batch (optional, for extensions)
    # @yield [record] Block to execute for each record
    def each_record(batch_size: nil)
      base_scope.each do |record|
        yield record
      end
    end
    # rubocop:enable Lint/UnusedMethodArgument

  private

    # Initializes export configuration.
    #
    # @param config [Object] The configuration object containing export settings
    # @return [void]
    def initialize_export(config)
      # Disable export if no formats are specified
      config.skip_export = true if config.export_formats.empty?
    end

    # The ClassMethods module provides methods for defining custom export methods for columns.
    module ClassMethods
      # Defines logic for a exporting a column to CSV/JSON.
      #
      # @param column_id [Symbol] The ID of the column
      # @param block [Proc] The block to define the export method
      # @return [void]
      def column_export(column_id, &block)
        column = find_column!(column_id)

        name = :"column_cell_export_#{column_id}"
        define_column_method(name, &block)
        column.export_method = name
      end

      # Defines logic for a exporting a column to CSV.
      #
      # @param column_id [Symbol] The ID of the column
      # @param block [Proc] The block to define the CSV method
      # @return [void]
      def column_csv(column_id, &block)
        column = find_column!(column_id)

        name = :"column_cell_csv_#{column_id}"
        define_column_method(name, &block)
        column.csv_method = name
      end

      # Defines logic for a exporting a column to JSON.
      #
      # @param column_id [Symbol] The ID of the column
      # @param block [Proc] The block to define the JSON method
      # @return [void]
      def column_json(column_id, &block)
        column = find_column!(column_id)

        name = :"column_cell_json_#{column_id}"
        define_column_method(name, &block)
        column.json_method = name
      end
    end
  end
end
