require "capybara/rails"
require "capybara/minitest"
require "capybara/cuprite"

# Configure Capybara for system tests with Cuprite
Capybara.configure do |config|
  config.default_driver = :cuprite
  config.javascript_driver = :cuprite
  config.default_max_wait_time = 5
  config.server = :puma, { Silent: true }
  config.disable_animation = true
end

build_driver = ->(app, window_size) do
  Capybara::Cuprite::Driver.new(
    app,
    window_size:,
    browser_options: {
      "no-sandbox" => nil,
      "disable-dev-shm-usage" => nil,
      "disable-gpu" => nil,
      "disable-web-security" => nil,
      "disable-features" => "VizDisplayCompositor",
    },
    headless: true,
    process_timeout: 60
  )
end

# Configure Cuprite options
Capybara.register_driver :cuprite_desktop do |app|
  build_driver.(app, [ 1200, 800 ])
end

Capybara.register_driver :cuprite_mobile do |app|
  build_driver.(app, [ 375, 667 ])
end

# Include Capybara DSL in system tests
class ActionDispatch::SystemTestCase
  include Capybara::DSL
  include Capybara::Minitest::Assertions
end
