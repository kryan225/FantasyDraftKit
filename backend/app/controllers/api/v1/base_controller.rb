module Api
  module V1
    class BaseController < ActionController::API
      # API-only controller base
      # Skip CSRF, sessions, cookies, etc.
    end
  end
end
