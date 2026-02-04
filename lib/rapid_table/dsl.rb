# frozen_string_literal: true

module RapidTable
  # Class-level DSL for defining tables.
  module DSL
    # Extends the base class with DSL functionality.
    def self.extended(base)
      base.class_eval do
        include RapidTable::Columns
        include RapidTable::Export
        include RapidTable::Search
        include RapidTable::Sorting

        include RapidTable::ColumnTypes
      end
    end
  end
end
