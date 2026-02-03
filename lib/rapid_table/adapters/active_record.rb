# frozen_string_literal: true

module RapidTable
  module Adapters
    # RapidTable rendering ActiveRecord relations.
    module ActiveRecord
      extend ActiveSupport::Concern

      included do
        include Search if included_modules.include?(RapidTable::Search)
        include Sorting if included_modules.include?(RapidTable::Sorting)
      end

      def each_record(batch_size: nil, skip_pagination: false, &block)
        collection = records
        collection = collection.unscope(:limit, :offset) if skip_pagination
        collection.find_each(batch_size:, &block)
      end

      def record_id(record)
        record.send(record.class.primary_key)
      end

      # RapidTable sorting functionality for ActiveRecord.
      module Sorting
        extend ActiveSupport::Concern

        included do
          register_filter :sorting, unless: :skip_sorting?

          column_class! do
            attr_accessor :nulls_last
            alias_method :nulls_last?, :nulls_last
          end
        end

        def filter_sorting(scope)
          return unless sort_column
          return filter_sorting_nulls_last(scope) if sort_column.nulls_last?

          scope.reorder(nil).order(sort_column.id => sort_order)
        end

        def filter_sorting_nulls_last(scope)
          # be extra careful about SQL injection here even though
          # these values should be coming our code, not the request.
          id = ::ActiveRecord::Base.connection.quote_column_name(sort_column.id)
          raise ArgumentEror unless %w[asc desc].include?(sort_order)

          scope.reorder(nil).order("#{id} #{sort_order} NULLS LAST")
        end
      end

      # RapidTable search functionality for ActiveRecord.
      module Search
        extend ActiveSupport::Concern

        included do
          # only search when the ActiveRecord class has a #search scope
          register_initializer :search_activerecord, after: :search do |table, config|
            config.skip_search = true unless table.active_record_class_has_search_scope?
          end
        end

        def filter_search(scope)
          scope.search(search_query)
        end

        def active_record_class_has_search_scope?
          base_scope.is_a?(::ActiveRecord::Relation) && base_scope.klass.respond_to?(:search)
        end
      end
    end
  end
end
