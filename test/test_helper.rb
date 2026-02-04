# frozen_string_literal: true
ENV["RAILS_ENV"] = "test"

unless RUBY_ENGINE == "truffleruby"
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
  end
end

require_relative "../test/dummy/config/environment"
require "rapid_table"

RapidTable::LOADER.eager_load

require "minitest/mock"
Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |f| require f }
