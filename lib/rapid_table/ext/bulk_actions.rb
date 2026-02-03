# frozen_string_literal: true

module RapidTable
  module Ext
    # The BulkActions module provides functionality for performing actions on multiple selected
    # records in RapidTable. It exposes the following configuration options to RapidTable::Base:
    #
    # @option config skip_bulk_actions [Boolean] Whether to disable bulk actions entirely
    # @option config bulk_actions [Array<BulkAction>] The bulk actions available for the table
    # @option config bulk_actions_param [Symbol] The parameter name for selected record IDs (default: :ids)
    #
    # Bulk action configuration:
    # @option config bulk_action.id [Symbol] The unique identifier for the bulk action
    # @option config bulk_action.label [String] The display label for the bulk action (optional)
    #
    # @example Basic usage
    #   class MyTable < RapidTable::Base
    #     self.skip_bulk_actions = false
    #     self.bulk_actions_param = :selected_ids
    #
    #     bulk_action :delete
    #     bulk_action :archive, label: "Archive Selected"
    #   end
    #
    # @example With bulk actions disabled
    #   class MyTable < RapidTable::Base
    #     self.skip_bulk_actions = true
    #   end
    module BulkActions
      extend ActiveSupport::Concern
      include Tags

      class BulkActionNotFoundError < RapidTable::Error; end

      included do
        extend ClassMethods

        config_attribute :skip_bulk_actions, default: false
        config_attribute :bulk_actions_param, default: :ids

        register_initializer :bulk_actions

        attr_accessor :bulk_actions

        config_class! do
          attr_accessor :bulk_actions
          attr_accessor :bulk_action_ids
        end

        def_extendable_class :bulk_action do
          attr_accessor :id
          attr_accessor :label
        end
      end

      # Gets the display label for a bulk action, with fallback to translation or titleized ID.
      #
      # @param bulk_action [Object] The bulk action object
      # @return [String] The display label for the bulk action
      def bulk_action_label(bulk_action)
        bulk_action.label || RapidTable.t("bulk_actions.#{bulk_action.id}", table_name:) || bulk_action.id.to_s.titleize
      end

      # Gets the IDs of records currently selected for bulk actions.
      #
      # @return [Array<String>] Array of selected record IDs
      def selected_bulk_action_record_ids
        # TODO: only retain these when just performed a bulk action
        @selected_bulk_action_record_ids ||= full_params[bulk_actions_param] || []
      end

      # Checks if a specific record is currently selected for bulk actions.
      #
      # @param record [Object] The record to check
      # @return [Boolean] True if the record is selected, false otherwise
      def selected_bulk_action_record?(record)
        selected_bulk_action_record_ids.include?(record_id(record).to_s)
      end

    private

      # Initializes bulk actions configuration and sets defaults.
      #
      # @param config [Object] The configuration object containing bulk action settings
      # @return [void]
      def initialize_bulk_actions(config)
        # Resolve bulk actions from DSL if not provided directly
        config.bulk_actions ||= resolve_bulk_actions(config)

        self.bulk_actions = self.class.build_bulk_actions(config.bulk_actions || [])

        # Disable bulk actions if none are defined
        config.skip_bulk_actions = true if bulk_actions.empty?
      end

      # Resolves bulk actions from DSL definitions (bulk_action_ids or class-level bulk_actions).
      #
      # @param config [Object] The configuration object
      # @return [Array, nil] The resolved bulk actions or nil
      def resolve_bulk_actions(config)
        ids = config.bulk_action_ids
        if ids
          ids.map { |id| self.class.find_bulk_action(id) }
        elsif self.class.bulk_actions.any?
          self.class.bulk_actions
        end
      end

      # Class methods for bulk action DSL configuration.
      module ClassMethods
        # Defines a new bulk action for this table.
        #
        # @param id [Symbol] The unique identifier for the bulk action
        # @param label [String, nil] The display label for the bulk action (optional)
        # @param options [Hash] Additional options for the bulk action
        # @return [Object] The created bulk action object
        # @example
        #   bulk_action :delete, label: "Delete Selected"
        def bulk_action(id, label: nil, **options)
          bulk_actions_by_id[id] = build_bulk_action(**options, id:, label:)
        end

        # Gets all defined bulk actions for this table.
        #
        # @return [Array<Object>] Array of bulk action objects
        def bulk_actions
          (superclass.respond_to?(:bulk_actions) ? superclass.bulk_actions : []) +
            bulk_actions_by_id.values
        end

        # Finds a bulk action by ID, searching up the inheritance chain.
        #
        # @param id [Symbol] The ID of the bulk action to find
        # @return [Object, nil] The found bulk action or nil if not found
        # @raise [RapidTable::Ext::BulkActions::NotFoundError] If the bulk action is not found
        def find_bulk_action(id)
          bulk_actions_by_id[id] ||
            (superclass&.find_bulk_action(id) if superclass.respond_to?(:find_bulk_action)) ||
            raise(RapidTable::Ext::BulkActions::BulkActionNotFoundError, "Bulk action #{id} not found")
        end

      private

        # Returns the registry of bulk actions by ID.
        #
        # @return [Hash<Symbol, Object>] The registry of bulk actions
        def bulk_actions_by_id
          @bulk_actions_by_id ||= {}
        end
      end
    end
  end
end
