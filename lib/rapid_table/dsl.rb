# frozen_string_literal: true

module RapidTable
  # Class-level DSL for defining tables.
  module DSL
    # Extends the base class with DSL functionality.
    def self.extended(base)
      base.class_eval do
        extend BulkActions

        include RapidTable::Columns
        include RapidTable::Export
        include RapidTable::Pagination
        include RapidTable::Search
        include RapidTable::Sorting
      end
    end
  end
end
