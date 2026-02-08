# JavaScript Controller Tests

This directory contains tests for Stimulus controllers using Jest and the Stimulus Testing Library approach.

## Current Status

Tests have been written for `BaseModalController` but are **not yet executable** because:
- This project uses `importmap-rails` (no npm/node_modules)
- Jest and testing dependencies are not installed
- Test runner configuration is not set up

## Running Tests (Future Setup)

When ready to run JavaScript tests, follow these steps:

### 1. Install Dependencies

```bash
cd backend
npm init -y  # Create package.json if it doesn't exist
npm install --save-dev \
  @hotwired/stimulus \
  @jest/globals \
  jest \
  jest-environment-jsdom
```

### 2. Configure Jest

Create `backend/jest.config.js`:

```javascript
export default {
  testEnvironment: 'jsdom',
  testMatch: ['**/spec/javascript/**/*.test.js'],
  transform: {},
  moduleNameMapper: {
    '^@hotwired/stimulus$': '<rootDir>/node_modules/@hotwired/stimulus/dist/stimulus.js'
  }
}
```

### 3. Add Test Script

Add to `backend/package.json`:

```json
{
  "scripts": {
    "test": "node --experimental-vm-modules node_modules/jest/bin/jest.js"
  },
  "type": "module"
}
```

### 4. Run Tests

```bash
npm test
```

## Test Coverage

### BaseModalController Tests

Located in: `spec/javascript/controllers/base_modal_controller.test.js`

**Covered Functionality:**
- ✅ Opening the modal (removes hidden class, prevents body scroll, dispatches event)
- ✅ Closing the modal (adds hidden class, restores scroll, resets form, dispatches event)
- ✅ Closing on outside click (overlay vs content)
- ✅ Escape key handling (closes modal, ignores other keys)
- ✅ Form submission handling (auto-close on success, re-enable button on error)
- ✅ setSubmitLoading helper (disables button, sets loading text)

**Total: 13 test cases**

## Writing New Tests

When creating tests for controllers that extend `BaseModalController`:

```javascript
import { Application } from "@hotwired/stimulus"
import YourModalController from "../../../app/javascript/controllers/your_modal_controller"

describe("YourModalController", () => {
  let application, container

  beforeEach(() => {
    container = document.createElement("div")
    container.innerHTML = `<!-- your HTML -->`
    document.body.appendChild(container)

    application = Application.start()
    application.register("your-modal", YourModalController)
  })

  afterEach(() => {
    application.stop()
    document.body.removeChild(container)
  })

  test("your test", () => {
    // Test implementation
  })
})
```

## Benefits of BaseModalController Tests

1. **Regression Prevention:** Tests catch breaking changes to modal behavior
2. **Documentation:** Tests serve as living documentation of expected behavior
3. **Confidence:** Refactoring is safer when tests exist
4. **Design Validation:** Tests validate the Single Responsibility Principle implementation
5. **Inheritance Safety:** Tests ensure child controllers inherit correct behavior

## Future Enhancements

- [ ] Set up CI/CD to run JavaScript tests automatically
- [ ] Add coverage reporting
- [ ] Add tests for DraftModalController (inherits from BaseModalController)
- [ ] Add integration tests using Capybara + Selenium for full UI testing
- [ ] Add performance benchmarks for modal open/close operations
