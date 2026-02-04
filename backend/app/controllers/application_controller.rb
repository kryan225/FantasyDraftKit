class ApplicationController < ActionController::Base
  # Skip CSRF protection for API endpoints only
  protect_from_forgery with: :exception, unless: -> { request.format.json? }
end
