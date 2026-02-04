# frozen_string_literal: true

require "test_helper"

class BaseTest < ActiveSupport::TestCase
  # TODO: These tests are pending - need to enable #url_for
  #
  # test "table_path adds a table param to support multiple tables in the same action" do
  #   table = RapidTable::Base.new([], param_name: :users)
  #   assert_equal "/users.csv?table=users", table.table_path
  # end
  #
  # test "table_path generates a path with the format at the top level with a param_name" do
  #   table = RapidTable::Base.new([], param_name: :users)
  #   assert_equal "/users.csv?table=users&users[page]=2", table.table_path(format: :csv, page: 2)
  # end
end
