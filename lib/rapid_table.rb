# frozen_string_literal: true

require "zeitwerk"
require "active_support/concern"
require "active_support/core_ext/string/inflections"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "dsl" => "DSL",
  "csv" => "CSV",
)
loader.collapse("#{__dir__}/rapid_table/concerns")
loader.ignore("#{__dir__}/generators")
loader.setup

# RapidTable is a gem for rendering tables in Rails applications.
module RapidTable
  class Error < StandardError; end
  class ExtensionRequiredError < Error; end
  class ExtendableClassNotFoundError < Error; end

  class << self
    def t(key, table_name:)
      I18n.t(
        "rapid_table.#{table_name}.#{key}",
        default: I18n.t("rapid_table.default.#{key}", default: nil),
      )
    end
  end
end

RapidTable::LOADER = loader
