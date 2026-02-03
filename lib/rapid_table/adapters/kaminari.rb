# frozen_string_literal: true

module RapidTable
  module Adapters
    # Kaminari functionality for RapidTable
    module Kaminari
      extend ActiveSupport::Concern

      included do
        include Pagination if included_modules.include?(RapidTable::Pagination)
      end

      # Kaminari Pagination functionality for RapidTable
      module Pagination
        extend ActiveSupport::Concern

        included do
          register_filter :pagination, unless: :skip_pagination?

          with_options to: :records do
            delegate :total_pages
            delegate :current_page
          end
        end

        def filter_pagination(scope)
          scope.page(page).per(per_page)
        end

        def total_records_count
          records.total_count
        end
      end
    end
  end
end
