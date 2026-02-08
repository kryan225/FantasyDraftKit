# Capybara configuration for system tests with JavaScript support
# Uses Cuprite (headless Chrome via Chrome DevTools Protocol)

require 'capybara/rspec'
require 'capybara/cuprite'

# Register Cuprite driver
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1400, 1400],
    browser_options: {
      'no-sandbox': nil,
      'disable-gpu': nil
    },
    process_timeout: 15,
    timeout: 10,
    js_errors: true,
    headless: !ENV['HEADLESS'].in?(['n', 'no', '0', 'false']),
    logger: STDOUT  # Enable console.log output
  )
end

# Configure Capybara
Capybara.configure do |config|
  config.default_driver = :rack_test          # Fast for non-JS tests
  config.javascript_driver = :cuprite         # Use Cuprite for JS tests
  config.default_max_wait_time = 5            # Wait up to 5s for elements
  config.server = :puma                       # Use Puma as test server
  config.server_errors = [:default]           # Raise server errors in tests
end

# RSpec configuration for system tests
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :cuprite
  end

  # Screenshot support for debugging
  config.after(:each, type: :system, js: true) do |example|
    if example.exception
      # Take screenshot on failure
      meta = example.metadata
      filename = File.basename(meta[:file_path])
      line_number = meta[:line_number]
      screenshot_name = "screenshot-#{filename}-#{line_number}.png"
      screenshot_path = "tmp/screenshots/#{screenshot_name}"
      
      FileUtils.mkdir_p('tmp/screenshots')
      page.save_screenshot(screenshot_path)
      
      puts "\n📸 Screenshot saved to: #{screenshot_path}"
    end
  end
end

# Helper to run tests with visible browser (for debugging)
# Usage: HEADLESS=false rspec spec/system/some_spec.rb
if ENV['HEADLESS'].in?(['n', 'no', '0', 'false'])
  puts "🔍 Running tests with VISIBLE browser (HEADLESS=false)"
end
