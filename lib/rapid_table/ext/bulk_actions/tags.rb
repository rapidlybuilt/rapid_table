# frozen_string_literal: true

module RapidTable
  module Ext
    module BulkActions
      # The Tags module provides helper methods for rendering bulk actions tags.
      module Tags
        extend ActiveSupport::Concern

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
      end
    end
  end
end
