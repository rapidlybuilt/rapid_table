require "capybara/rspec"
require "capybara/cuprite"

# https://github.com/rubycdp/cuprite/issues/77
browser_options = { 'no-sandbox': true, 'disable-gpu': true }

Capybara.disable_animation = true
Capybara.raise_server_errors = true

Capybara.register_driver :cuprite_desktop do |app|
  # debug with: page.driver.debug(binding)
  # logger = StringIO.new
  Capybara::Cuprite::Driver.new(app, window_size: [ 1200, 800 ], inspector: ENV['INSPECTOR'], process_timeout: 30, browser_options:)
end

Capybara.register_driver :cuprite_mobile do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [ 375, 667 ], inspector: ENV['INSPECTOR'], process_timeout: 30, browser_options:)
end

module CapybaraSupport
  extend ActiveSupport::Concern

  def refresh_page
    page.execute_script("window.location.reload()")
  end

  def remove_field(field_name)
    el = page.find_field(field_name)
    page.execute_script("arguments[0].remove()", el)
  end

  class_methods do
    def swallow_server_errors
      around do |example|
        old = Capybara.raise_server_errors
        Capybara.raise_server_errors = false
        example.run
        Capybara.raise_server_errors = old
      end
    end
  end
end

RSpec.configure do |config|
  config.include CapybaraSupport, type: :system
  config.include Capybara::DSL, type: :system

  config.before(:each, type: :system) do
    driven_by(:cuprite_desktop)
  end

  config.before(:each, type: :system, desktop: true) do
    driven_by(:cuprite_desktop)
  end

  config.before(:each, type: :system, mobile: true) do
    driven_by(:cuprite_mobile)
  end

  config.before(:each, type: :system, nojs: true) do
    driven_by(:rack_test)
  end
end
