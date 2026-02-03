# frozen_string_literal: true

module RapidTable
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

    class NotFoundError < Error; end

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

    # Renders a "select all" checkbox for bulk actions.
    #
    # @param options [Hash] Additional HTML options for the checkbox
    # @return [String] The rendered checkbox HTML
    def bulk_actions_select_all_check_box_tag(**options)
      template.check_box_tag(
        "select_all",
        nil,
        false,
        **options,
        data: hotwire_data(
          options,
          action: stimulus_actions(
            "change", "toggleBulkActionsSelections",
            "change", "toggleBulkActionPerform",
          ),
        ),
      )
    end

    # Renders a checkbox for selecting an individual record for bulk actions.
    #
    # @param record [Object] The record to create a checkbox for
    # @param options [Hash] Additional HTML options for the checkbox
    # @return [String] The rendered checkbox HTML
    def bulk_actions_select_one_check_box_tag(record, **options)
      id = record_id(record)

      template.check_box_tag(
        "#{bulk_actions_param}[]",
        id,
        selected_bulk_action_record?(record),
        id: "#{table_name}_select_#{id}",
        title: "Select",
        **options,
        data: hotwire_data(
          options,
          stimulus_target => "bulkActionsRowSelect",
          action: stimulus_action("change", "toggleBulkActionPerform"),
        ),
      )
    end

    # Renders a select dropdown for choosing which bulk action to perform.
    #
    # @param options [Hash] Additional HTML options for the select tag
    # @return [String] The rendered select tag HTML
    def bulk_actions_select_tag(**options)
      placeholder_choice = [t("bulk_actions.placeholder"), nil]
      choices = bulk_actions.map { |bulk_action| [bulk_action_label(bulk_action), bulk_action.id] }

      template.select_tag(
        nil, # JavaScript cleverness will submit the bulk action
        options_for_select([placeholder_choice] + choices),
        id: id_for(:bulk_actions),
        **options,
        data: hotwire_data(
          options,
          action: stimulus_action("change", "toggleBulkActionPerform"),
          stimulus_target => "bulkActionSelect",
        ),
      )
    end

    # Renders a submit button for performing the selected bulk action.
    #
    # @param path [String] The URL to submit the bulk action to (defaults to bulk_action action)
    # @param method [String] The HTTP method for the form (default: "POST")
    # @param options [Hash] Additional HTML options for the submit button
    # @return [String] The rendered submit button HTML
    def bulk_actions_submit_tag(path: table_path(action: :bulk_action), method: "POST", **options)
      template.submit_tag(
        t("bulk_actions.button"),
        title: t("bulk_actions.button_title"),
        **options,
        data: hotwire_data(
          options,
          action: stimulus_action("click", "submitBulkAction"),
          stimulus_target => "bulkActionPerform",
          param: bulk_actions_param,
          path:,
          method:,
        ),
      )
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
      # @raise [RapidTable::BulkActions::NotFoundError] If the bulk action is not found
      def find_bulk_action(id)
        bulk_actions_by_id[id] ||
          (superclass&.find_bulk_action(id) if superclass.respond_to?(:find_bulk_action)) ||
          raise(RapidTable::BulkActions::NotFoundError, "Bulk action #{id} not found")
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
