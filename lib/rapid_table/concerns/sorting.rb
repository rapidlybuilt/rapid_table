# frozen_string_literal: true

module RapidTable
  # The Sorting module provides functionality for sorting table data in RapidTable.
  # It exposes the following configuration options to RapidTable::Base:
  #
  # @option config skip_sorting [Boolean] Whether to disable sorting functionality entirely
  # @option config sort_column_param [Symbol] The parameter name for the sort column (default: :sort)
  # @option config sort_order_param [Symbol] The parameter name for the sort order (default: :dir)
  # @option config sort_column [Symbol] The default column to sort by (default: nil)
  # @option config sort_order [String] The default sort order (default: "asc")
  #
  # Column-level sorting options:
  # @option config column.sortable [Boolean] Whether this column is sortable (default: false)
  # @option config column.sort_order [String] The default sort order for this column (default: "asc")
  #
  # @example Basic usage
  #   class MyTable < RapidTable::Base
  #     self.skip_sorting = false
  #     self.sort_column = :name
  #     self.sort_order = :asc
  #   end
  #
  # @example With sorting disabled
  #   class MyTable < RapidTable::Base
  #     self.skip_sorting = true
  #   end
  module Sorting
    extend ActiveSupport::Concern

    included do
      include Columns
      extend ClassMethods

      config_attribute :skip_sorting, default: false
      config_attribute_param :sort_column_param, default: :sort
      config_attribute_param :sort_order_param, default: :dir

      register_initializer :sorting, after: :columns
      register_filter :sorting, unless: :skip_sorting?

      config_class! do
        attr_accessor :sort_column
        attr_accessor :sort_order
      end

      column_class! do
        attr_accessor :sortable, :sort_order
        alias_method :sortable?, :sortable
      end

      # Add sort_column and sort_order to column groups if available
      column_group_class! do
        attr_accessor :sort_column, :sort_order
      end
    end

    # Class methods for sort configuration via column groups.
    module ClassMethods
      # Gets the default sort column for this table.
      #
      # @return [Symbol, nil] The sort column ID or nil if not set
      def sort_column
        default_column_group.sort_column
      end

      # Sets the default sort column for this table.
      #
      # @param id [Symbol] The column ID to sort by
      # @return [Object] The modified column group
      def sort_column=(id)
        default_column_group.tap do |group|
          group.sort_column = id
        end
      end

      # Gets the default sort order for this table.
      #
      # @return [String, nil] The sort order ("asc" or "desc") or nil if not set
      def sort_order
        default_column_group.sort_order
      end

      # Sets the default sort order for this table.
      #
      # @param order [String] The sort order ("asc" or "desc")
      # @return [Object] The modified column group
      def sort_order=(order)
        default_column_group.tap do |group|
          group.sort_order = order
        end
      end
    end

    def sort_column
      return @sort_column if defined?(@sort_column)

      sort_column_id = sort_column_param_value || config.sort_column
      return unless sort_column_id.is_a?(Symbol) || sort_column_id.is_a?(String)

      @sort_column = find_sortable_column(sort_column_id)
      Rails.logger.warn("Sortable column #{sort_column_id} not found") unless @sort_column
      @sort_column
    end

    def sort_order
      return @sort_order if defined?(@sort_order)

      @sort_order = (sort_order_param_value || sort_column&.sort_order)&.to_s
      @sort_order = "asc" if @sort_order.blank?
      @sort_order
    end

    def filter_sorting(_scope)
      raise ExtensionRequiredError
    end

    def sort_column_param_value
      value = params[sort_column_param]
      value = nil if value.present? && !find_sortable_column(value)
      value
    end

    def available_sort_orders
      %w[asc desc]
    end

    def reverse_sort_order(order)
      return "asc" if order == "desc"

      "desc"
    end

    def sort_order_param_value
      value = params[sort_order_param]
      value = nil if value && !available_sort_orders.include?(value)
      value
    end

    def column_label(column)
      label = determine_column_label(column)
      return tag.span(label) if skip_sorting? || !column.sortable?

      so = sort_column&.id == column.id ? reverse_sort_order(sort_order) : column.sort_order

      link_to(
        h(label) << sort_order_label(column),
        table_path(sort_column_param => column.id, sort_order_param => so),
        class: "admin-table-header-cell-link",
        data: { turbo_stream: },
      )
    end

    def sort_order_label(column)
      return "" unless column.sortable?

      tag.span(sort_order_icon_label(column), class: "admin-table-header-sort-order")
    end

    def sort_order_icon_label(column)
      return h("") unless column.sortable?

      if sort_column&.id != column.id
        "▲<br/>▼".html_safe
      elsif sort_order == "asc"
        "▲<br/>&nbsp;".html_safe
      else
        "&nbsp;<br/>▼".html_safe
      end
    end

  private

    def initialize_sorting(config)
      # Copy sort_column and sort_order from column group if available
      column_group_id = config.column_group_id
      return unless column_group_id

      column_group = self.class.find_column_group!(column_group_id)
      config.sort_column ||= column_group.sort_column
      config.sort_order ||= column_group.sort_order
    end

    def find_sortable_column(id)
      columns.find { |column| column.sortable? && column.id.to_s == id.to_s }
    end
  end
end
