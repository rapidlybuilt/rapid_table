# frozen_string_literal: true

module RapidTable
  # The Columns module provides functionality for defining and managing table columns
  # in RapidTable. It exposes the following configuration options to RapidTable::Base:
  #
  # @option config columns [Array<Hash, Column>] The columns to display in the table.
  #   Can be specified as:
  #   - Hashes: columns [{id: :name, label: "Full Name"}, {id: :email, cell_method: :formatted_email}]
  #   - Column objects: columns [column1, column2]
  # @option config column_ids [Array<Symbol>] Column IDs to include (via DSL)
  # @option config column_group_id [Symbol] Column group ID to use (via DSL)
  # @option config except [Array, Symbol] Column IDs to exclude from the table
  # @option config only [Array, Symbol] Column IDs to include in the table
  #
  # When using hashes, each hash supports:
  # @option config column.id [Symbol] The column identifier
  # @option config column.label [String] The column label (optional)
  # @option config column.cell_method [Symbol] The method to call for cell rendering (optional)
  #
  # @example Basic DSL usage
  #   class MyTable < RapidTable::Base
  #     column :id
  #     column :name
  #     column :email
  #     column :created_at
  #
  #     # implied cell method
  #     def email_cell(record)
  #       record.email.downcase
  #     end
  #   end
  #
  # @example With custom labels and cell methods
  #   class MyTable < RapidTable::Base
  #     column :id, label: "ID"
  #     column :name, label: "Full Name"
  #     column :email, cell_method: :formatted_email
  #
  #     # explicitly specified cell method
  #     def formatted_email(record)
  #       record.email.downcase
  #     end
  #   end
  #
  # @example With column groups
  #   class MyTable < RapidTable::Base
  #     column :id
  #     column :name
  #     column :email
  #     column :created_at
  #
  #     # allow rendering this table with a preconfigured subset of columns
  #     column_group :basic, [:name, :email]
  #   end
  module Columns
    extend ActiveSupport::Concern

    included do
      extend ClassMethods

      attr_accessor :columns

      register_initializer :columns

      config_class! do
        include Config
      end

      def_extendable_class :column do
        attr_accessor :id
        attr_accessor :label
        attr_accessor :cell_method

        def cell_method
          @cell_method ||= :"#{id}_cell"
        end
      end

      def_extendable_class :column_group do
        attr_accessor :id
        attr_accessor :column_ids
      end
    end

    # Renders the label for a given column.
    #
    # @param column [Object] The column object containing id and label information
    # @return [String] The rendered HTML span element containing the column label
    def column_label(column)
      tag.span(determine_column_label(column))
    end

    # Renders the cell content for a given record and column.
    #
    # @param record [Object] The record object to render the cell for
    # @param column [Object] The column object defining how to render the cell
    # @return [String] The rendered cell content
    def column_cell(record, column)
      return send(column.cell_method, record) if respond_to?(column.cell_method, true)

      value = record.send(column.id)
      column_type_value(value) || value
    end

  private

    # Initializes the columns configuration from the provided config object.
    #
    # @param config [Object] The configuration object containing column definitions
    # @raise [ArgumentError] If no columns are specified in the configuration
    # @return [void]
    def initialize_columns(config)
      config.columns ||= resolve_columns(config) || raise(ArgumentError, "columns must be specified")

      columns = self.class.build_columns(config.columns)
      self.columns = filter_columns(columns)
    end

    # Resolves columns from DSL definitions (column_ids or column_group_id).
    #
    # @param config [Object] The configuration object
    # @return [Array, nil] The resolved columns or nil if no DSL columns defined
    def resolve_columns(config)
      return unless config.column_ids || config.column_group_id || self.class.columns.any?

      # Default to :default column group if neither is specified but DSL columns exist
      config.column_group_id ||= :default unless config.column_ids

      self.class.find_columns!(
        column_ids: config.column_ids,
        column_group_id: config.column_group_id,
      )
    end

    # Determines the appropriate label for a column.
    #
    # @param column [Object] The column object
    # @return [String] The column label
    def determine_column_label(column)
      id = column.id
      column.label || RapidTable.t("columns.#{id}", table_name:) || id.to_s.titleize
    end

    # Attempts to find a type-specific cell helper method for the given value.
    #
    # @param value [Object] The value to render
    # @return [String, nil] The rendered value or nil if no helper method exists
    def column_type_value(value)
      klass = value.class
      # OPTIMIZE: cache the results so we're not introspecting every time

      helper = :"#{klass.name.underscore.gsub("/", "_")}_cell"
      return unless respond_to?(helper, true)

      send(helper, value)
    end

    # Filters columns based on the only and except configuration options.
    #
    # @param columns [Array] The array of columns to filter
    # @return [Array] The filtered array of columns
    def filter_columns(columns)
      except = config.except
      only = config.only

      columns = columns.reject { |column| except.include?(column.id) } if except
      columns = columns.select { |column| only.include?(column.id) } if only
      columns
    end

    # Class methods for column DSL configuration.
    module ClassMethods
      # Defines a new column for this table.
      #
      # @param id [Symbol] The unique identifier for the column
      # @param options [Hash] Additional options for the column (label, cell_method, etc.)
      # @return [Object] The created column object
      # @example
      #   column :id, label: "ID"
      #   column :email, cell_method: :formatted_email
      def column(id, **options)
        columns_by_id[id] = build_column(**options, id:)
      end

      # Defines a new column group for this table.
      #
      # @param id [Symbol] The unique identifier for the column group
      # @param column_ids [Array<Symbol>] The column IDs to include in this group
      # @param options [Hash] Additional options for the column group
      # @return [Object] The created column group object
      # @example
      #   column_group :basic_info, [:id, :name, :email]
      def column_group(id, column_ids, **options)
        column_groups_by_id[id] = build_column_group(**options, id:, column_ids:)
      end

      # Gets all defined columns for this table, including inherited ones.
      #
      # @return [Array<Object>] Array of column objects
      def columns
        ((superclass&.columns if superclass.respond_to?(:columns)) || []) +
          columns_by_id.values
      end

      # Gets all defined column groups for this table, including inherited ones.
      #
      # @return [Array<Object>] Array of column group objects
      def column_groups
        ((superclass&.column_groups if superclass.respond_to?(:column_groups)) || []) +
          column_groups_by_id.values
      end

      # Finds a column by ID, searching up the inheritance chain.
      #
      # @param column_id [Symbol] The ID of the column to find
      # @return [Object, nil] The found column or nil if not found
      def find_column(column_id)
        columns_by_id[column_id] ||
          (superclass&.find_column(column_id) if superclass.respond_to?(:find_column))
      end

      # Finds a column by ID, raising an error if not found.
      #
      # @param column_id [Symbol] The ID of the column to find
      # @return [Object] The found column
      # @raise [RapidTable::ColumnNotFoundError] If the column is not found
      def find_column!(column_id)
        find_column(column_id) || raise(RapidTable::ColumnNotFoundError, "Column #{column_id} not found")
      end

      # Finds a column group by ID, searching up the inheritance chain.
      #
      # @param group_id [Symbol] The ID of the column group to find
      # @return [Object, nil] The found column group or nil if not found
      def find_column_group(group_id)
        column_groups_by_id[group_id] ||
          (define_default_column_group if group_id == :default) ||
          (superclass.find_column_group(group_id) if superclass.respond_to?(:find_column_group))
      end

      # Finds a column group by ID, raising an error if not found.
      #
      # @param group_id [Symbol] The ID of the column group to find
      # @return [Object] The found column group
      # @raise [RapidTable::ColumnGroupNotFoundError] If the column group is not found
      def find_column_group!(group_id)
        find_column_group(group_id) || raise(RapidTable::ColumnGroupNotFoundError, "Column group #{group_id} not found")
      end

      # Finds columns by IDs or column group ID.
      #
      # @param column_ids [Array<Symbol>, nil] The column IDs to find
      # @param column_group_id [Symbol, nil] The column group ID to find columns for
      # @return [Array<Object>] Array of found column objects
      # @raise [ArgumentError] If both column_ids and column_group_id are specified
      # @raise [ArgumentError] If neither column_ids nor column_group_id is specified
      def find_columns!(column_ids: nil, column_group_id: nil)
        raise ArgumentError, "column_ids and column_group_id cannot be used together" if column_ids && column_group_id

        if column_ids
          column_ids.map { |id| find_column!(id) }
        elsif column_group_id
          find_columns!(column_ids: find_column_group!(column_group_id).column_ids)
        else
          raise ArgumentError, "column_ids or column_group_id must be specified"
        end
      end

      # Returns the default column group.
      #
      # @return [Object] The default column group
      def default_column_group
        column_groups_by_id[:default] || define_default_column_group
      end

    private

      # Returns the registry of columns by ID.
      #
      # @return [Hash<Symbol, Object>] The registry of columns
      def columns_by_id
        @columns_by_id ||= {}
      end

      # Returns the registry of column groups by ID.
      #
      # @return [Hash<Symbol, Object>] The registry of column groups
      def column_groups_by_id
        @column_groups_by_id ||= {}
      end

      # Defines the default column group containing all columns.
      #
      # @return [Object] The default column group
      def define_default_column_group
        column_group(:default, columns.map(&:id))
      end
    end

    # Extension to the table's configuration class.
    module Config
      attr_accessor :columns
      attr_accessor :column_ids
      attr_accessor :column_group_id
      attr_writer :except
      attr_writer :only

      # Returns the except configuration as an array.
      #
      # @return [Array] The array of column IDs to exclude
      def except
        ensure_array(@except)
      end

      # Returns the only configuration as an array.
      #
      # @return [Array] The array of column IDs to include
      def only
        ensure_array(@only)
      end

    private

      # Ensures a value is returned as an array.
      #
      # @param value [Object] The value to convert to an array
      # @return [Array] The value as an array
      def ensure_array(value)
        value = [value] if value && !value.is_a?(Array)
        value
      end
    end
  end
end
