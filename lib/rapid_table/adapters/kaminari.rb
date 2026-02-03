# frozen_string_literal: true

module RapidTable
  module Adapters
    # Kaminari functionality for RapidTable
    module Kaminari
      extend ActiveSupport::Concern
      include RapidTable::Ext::Pagination

      included do
        register_filter :kaminari, unless: :skip_pagination?

        with_options to: :records do
          delegate :total_pages
          delegate :current_page
        end
      end

      def filter_kaminari(scope)
        scope.page(page).per(per_page)
      end

      def total_records_count
        records.total_count
      end
    end
  end
end
