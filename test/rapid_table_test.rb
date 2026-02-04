# frozen_string_literal: true

require "test_helper"

class RapidTableTest < ActiveSupport::TestCase
  test "has a version number" do
    refute_nil RapidTable::VERSION
  end
end
