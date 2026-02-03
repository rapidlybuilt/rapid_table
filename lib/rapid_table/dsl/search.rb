# frozen_string_literal: true

module RapidTable
  module DSL
    # The Search DSL module provides class-level configuration for search functionality
    # in RapidTable.
    #
    # @example Basic usage
    #   class MyTable < RapidTable::Base
    #     self.skip_search = false
    #     self.search_param = :search
    #   end
    #
    # @example With search disabled
    #   class MyTable < RapidTable::Base
    #     self.skip_search = true
    #   end
    module Search
      # Extends the base class with search DSL functionality.
      #
      # @param base [Class] The table class to extend
      def self.extended(base)
        base.class_eval do
          include RapidTable::Search

          config_attribute :skip_search, default: false
          config_attribute :search_param, default: :q
        end
      end
    end
  end
end
