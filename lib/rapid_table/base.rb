# frozen_string_literal: true

require "view_component"

module RapidTable
  # Base class for all tables
  class Base < ViewComponent::Base
    include RapidTable::Support

    attr_reader :id
    attr_reader :base_scope
    attr_reader :table_name
    attr_reader :config

    with_options to: :records do
      delegate :empty?
      delegate :any?
    end

    def initialize(base_scope, id: nil, **options, &block)
      ensure_base_scope_or_block(base_scope, block)

      super()

      @base_scope = base_scope || block

      @id = id || self.class.name.underscore.gsub("/", "_") if self.class.name
      @table_name = self.class.table_name

      apply_initializers(options)
    end

    def records
      @records ||= apply_filters(@base_scope)
    end

    def empty_message
      t("empty_message")
    end

    def dom_id(record)
      super if record.respond_to?(:to_key)
    end

    def record_id(_record)
      raise ExtensionRequiredError
    end

    def table_path(view_context: self, format: nil, **options)
      options = options.reverse_merge(registered_params)
      if param_name
        view_context.url_for(action: action_name, table: param_name, param_name => options, format:)
      else
        view_context.url_for(action: action_name, format:, table: "", **options)
      end
    end

  private

    def t(key)
      RapidTable.t(key, table_name:)
    end

    def ensure_base_scope_or_block(base_scope, block)
      raise ArgumentError, "records or block is required" if base_scope.nil? && block.nil?
      raise ArgumentError, "records and block cannot be used together" if base_scope.present? && block.present?
    end

    class << self
      def table_name
        name&.underscore
      end
    end
  end
end
