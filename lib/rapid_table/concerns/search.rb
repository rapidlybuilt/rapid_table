# frozen_string_literal: true

module RapidTable
  # The Search module provides functionality for searching and filtering table data in RapidTable.
  # It exposes the following configuration options to RapidTable::Base:
  #
  # @option config skip_search [Boolean] Whether to disable search functionality entirely
  # @option config search_param [Symbol] The parameter name for the search query (default: :q)
  module Search
    extend ActiveSupport::Concern

    included do
      config_attribute :skip_search, default: false
      config_attribute_param :search_param, default: :q

      register_filter :search, unless: :skip_search?
    end

    # Gets the current search query from the request parameters.
    #
    # @return [String, nil] The search query from params, or nil if not present
    def search_query
      params[search_param]
    end

    # Renders a search input field with the current search query.
    #
    # @param options [Hash] Additional HTML options for the input tag
    # @return [String] The rendered search input HTML
    def search_field_tag(options = {})
      helpers.search_field_tag(
        param_name(search_param),
        search_query,
        id: id_for(:search),
        **options,
        placeholder: t("search.placeholder"),
      )
    end

    # Renders a search form with the search field and hidden parameters.
    #
    # @param url [String] The form action URL (defaults to current action)
    # @param method [Symbol] The HTTP method for the form (default: :get)
    # @param options [Hash] Additional HTML options for the form tag
    # @yield [void] Optional block for custom form content
    # @return [String] The rendered search form HTML
    def search_field_form(url: url_for(action: action_name), method: :get, **options, &block)
      form_tag(url, method:, **options.merge(data: { turbo_stream: })) do
        search = block_given? ? capture(&block) : search_field_tag
        hidden_fields_for_registered_params(additional_params: { page: 1 }, except: search_param) << search
      end
    end

    # Filters the scope based on the search query. Must be implemented by extensions.
    #
    # @param scope [Object] The scope to filter (e.g., ActiveRecord::Relation)
    # @return [Object] The filtered scope
    # @raise [ExtensionRequiredError] If no extension provides this functionality
    def filter_search(_scope)
      raise ExtensionRequiredError, "not implemented"
    end
  end
end
