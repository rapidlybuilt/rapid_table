# frozen_string_literal: true

module RapidTable
  # The ColumnTypes module provides standard column type definitions for RapidTable.
  # Each type defines how values of that type should be rendered in HTML output.
  #
  # @example Using column types
  #   class MyTable < RapidTable::Base
  #     columns do |t|
  #       t.string :name
  #       t.integer :age
  #       t.float :price
  #       t.date :birthday
  #       t.datetime :created_at
  #     end
  #   end
  module ColumnTypes
    extend ActiveSupport::Concern

    # rubocop:disable Metrics/BlockLength
    included do
      # Renders a string value.
      column_type :string, &:to_s

      # Renders an integer value with thousands separators.
      # @example 1234567 => "1,234,567"
      column_type :integer do |value|
        number_with_delimiter(value.to_i)
      end

      # Renders a float/decimal value with thousands separators and 2 decimal places.
      # @example 1234.5 => "1,234.50"
      column_type :float do |value|
        number_with_delimiter(format("%.2f", value.to_f))
      end

      # Renders a date in a human-readable format.
      # Uses I18n localization with :long format if available.
      # @example Date.new(2024, 1, 15) => "January 15, 2024"
      column_type :date do |value|
        value = value.to_date if value.respond_to?(:to_date) && !value.is_a?(Date)
        I18n.l(value, format: :long, default: value.strftime("%B %-d, %Y"))
      end

      # Renders a datetime in a human-readable format with time.
      # Uses I18n localization with :long format if available.
      # @example DateTime.new(2024, 1, 15, 14, 30) => "January 15, 2024 at 2:30 PM"
      column_type :datetime do |value|
        value = value.to_datetime if value.respond_to?(:to_datetime) && !value.is_a?(DateTime) && !value.is_a?(Time)
        I18n.l(value, format: :long, default: value.strftime("%B %-d, %Y at %-l:%M %p"))
      end

      # Renders a boolean value as "Yes" or "No".
      # @example true => "Yes", false => "No"
      column_type :boolean do |value|
        value ? "Yes" : "No"
      end

      # Renders a currency value with dollar sign and 2 decimal places.
      # @example 1234.5 => "$1,234.50"
      column_type :currency do |value|
        number_to_currency(value)
      end

      # Renders a percentage value.
      # If value < 1, assumes decimal (0.75 = 75%), otherwise assumes percentage (75 = 75%).
      # @example 0.75 => "75.00%", 75 => "75.00%"
      column_type :percentage do |value|
        percentage = value.to_f
        percentage *= 100 if percentage.abs < 1
        number_to_percentage(percentage, precision: 2)
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
