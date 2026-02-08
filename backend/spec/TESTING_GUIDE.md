# Testing Guide for FantasyDraftKit

## Overview

This project uses RSpec for testing with the following setup:

- **Model/Controller Tests**: Standard RSpec unit tests
- **System Tests (Frontend)**: Capybara + Cuprite for JavaScript-enabled browser testing
- **Test Framework**: RSpec 3.x
- **Test Data**: FactoryBot for fixtures

## Frontend Testing Setup

### Technology Stack

**Cuprite** - Headless Chrome driver via Chrome DevTools Protocol
- Fast (2-3x faster than Selenium)
- No driver binary management (no ChromeDriver needed)
- Works directly with Chrome/Chromium via CDP
- Perfect for Hotwire (Turbo + Stimulus) applications
- Lightweight and CI/CD friendly

### Configuration Files

1. **`spec/support/capybara.rb`** - Capybara and Cuprite configuration
   - Registers `:cuprite` driver for JavaScript tests
   - Configures default drivers (`:rack_test` for non-JS, `:cuprite` for JS)
   - Sets up screenshot capture on test failures
   - Enables visible browser mode with `HEADLESS=false`

2. **`spec/rails_helper.rb`** - Loads support files and configures RSpec
   - Requires all files in `spec/support/`
   - Includes FactoryBot methods globally
   - Configures transactional fixtures

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run system tests only
bundle exec rspec spec/system

# Run specific test file
bundle exec rspec spec/system/edit_player_modal_spec.rb

# Run with visible browser (for debugging)
HEADLESS=false bundle exec rspec spec/system/edit_player_modal_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

### Writing System Tests

#### Basic Structure

```ruby
require 'rails_helper'

RSpec.describe "FeatureName", type: :system, js: true do
  # The `js: true` flag enables JavaScript via Cuprite
  
  it "does something interactive" do
    visit some_path
    
    click_link "Button Text"
    
    expect(page).to have_content("Expected Text")
  end
end
```

#### Key Patterns

**Waiting for JavaScript:**
```ruby
# Capybara automatically waits up to 5 seconds (configured in capybara.rb)
expect(page).to have_css(".modal", visible: :visible)

# Custom wait time
expect(page).to have_content("Loaded", wait: 10)
```

**Testing Modals:**
```ruby
# Check modal opens
click_link "Open Modal"
expect(page).to have_css(".modal", visible: :visible)
expect(page).not_to have_css(".modal.hidden")

# Check modal closes
page.driver.browser.keyboard.type(:Escape)
expect(page).to have_css(".modal.hidden", visible: :hidden)
```

**Form Interactions:**
```ruby
within(".modal") do
  fill_in "Field Name", with: "New Value"
  check "Checkbox Label"
  select "Option", from: "Dropdown"
  click_button "Submit"
end
```

**Testing Stimulus Controllers:**
```ruby
# Click element with data-action
find("[data-action='click->modal#open']").click

# Check for data attributes
expect(page).to have_css("[data-controller='modal']")
expect(page).to have_css("[data-modal-target='content']")
```

**Database Assertions:**
```ruby
# Reload model to see database changes
player.reload
expect(player.name).to eq("Updated Name")
```

#### Testing Best Practices

1. **Use `:aggregate_failures`** for multiple assertions:
   ```ruby
   it "tests multiple things", :aggregate_failures do
     expect(x).to eq(1)
     expect(y).to eq(2)
     # All failures reported, not just first
   end
   ```

2. **Use `within` blocks** for scoping:
   ```ruby
   within(".modal") do
     # Only searches within modal
     click_button "Save"
   end
   ```

3. **Test behavior, not implementation**:
   ```ruby
   # Good - tests user-visible behavior
   it "updates player name" do
     click_link player.name
     fill_in "Player Name", with: "New Name"
     click_button "Save"
     expect(page).to have_content("New Name")
   end
   
   # Bad - tests internal implementation
   it "calls update method" do
     expect(controller).to receive(:update)
     # ...
   end
   ```

4. **Use descriptive test names**:
   ```ruby
   # Good
   it "opens modal when clicking player name"
   
   # Bad
   it "works"
   ```

### Debugging Tests

#### Screenshot on Failure

Tests automatically capture screenshots on failure:
```bash
📸 Screenshot saved to: tmp/screenshots/screenshot-edit_player_modal_spec.rb-77.png
```

Screenshots are also saved to:
```bash
tmp/capybara/failures_r_spec_example_groups_...png
```

#### Visible Browser Mode

Run tests with visible browser to watch what happens:
```bash
HEADLESS=false bundle exec rspec spec/system/edit_player_modal_spec.rb
```

This opens an actual Chrome window so you can see the test execution.

#### Debug with Pry

Add `binding.pry` in your test:
```ruby
it "debugs something" do
  visit players_path
  binding.pry  # Execution stops here
  click_link "Something"
end
```

At the pry console:
```ruby
page.body              # See page HTML
page.save_screenshot   # Save screenshot manually
page.driver.debug      # Cuprite debug console
```

#### Check Capybara's View

```ruby
# In test, print the page HTML
puts page.body

# Save and open page in browser
save_and_open_page
```

### Common Issues and Solutions

#### Issue: "Unable to find..."

**Problem**: Element not found on page

**Solutions**:
1. Wait for element: `expect(page).to have_css(".element", wait: 10)`
2. Check element is visible: `visible: :visible`
3. Use `within` if element is in a specific container
4. Take screenshot to see actual page state

#### Issue: "Ambiguous match"

**Problem**: Multiple elements match selector

**Solutions**:
1. Use `within` to scope search
2. Use more specific selector: `find(".modal .submit-button")`
3. Use `:first` if appropriate: `find(".button", match: :first)`

#### Issue: "Stale element reference"

**Problem**: Element was found but DOM changed

**Solutions**:
1. Find element fresh each time: `find(".button").click`
2. Don't store elements: `button = find(".btn"); button.click` (BAD)

#### Issue: Test passes locally but fails in CI

**Problem**: Timing issues or environment differences

**Solutions**:
1. Increase wait times: `Capybara.default_max_wait_time = 10`
2. Use explicit waits: `expect(page).to have_content("...", wait: 10)`
3. Ensure database is properly seeded

### Test Coverage

Current coverage (as of 2026-02-08):

- ✅ EditPlayerModal: 6 tests covering open/close, form population, validation
- ✅ DraftBoardController: Tests for league resolution
- ⏳ DraftModal: Needs JavaScript-enabled tests
- ⏳ Player model: Needs comprehensive unit tests
- ⏳ API endpoints: Needs request specs

### Future Improvements

1. **Add more system tests**:
   - Draft player modal workflow
   - Team budget updates
   - Player filtering and search

2. **Add request specs for API**:
   - Test JSON API endpoints
   - Test authentication/authorization (when added)

3. **Add model specs**:
   - Test validations
   - Test scopes
   - Test callbacks

4. **Performance testing**:
   - Ensure tests run under 30 seconds total
   - Profile slow tests with `--profile` flag

## Resources

- [RSpec Documentation](https://rspec.info/)
- [Capybara Documentation](https://github.com/teamcapybara/capybara)
- [Cuprite Documentation](https://github.com/rubycdp/cuprite)
- [FactoryBot Documentation](https://github.com/thoughtbot/factory_bot)
