# frozen_string_literal: true

# ValueCalculatorService
#
# Service wrapper for ValueCalculator concern.
# Provides error handling, timing, and logging around value calculation.
#
# Usage:
#   service = ValueCalculatorService.new(league)
#   result = service.call
#   # => { count: 247, min_value: 1.0, max_value: 45.3, avg_value: 12.6, elapsed_time: 0.15 }
#
# Can be called from:
# - Controllers (API and web UI)
# - Rake tasks
# - Background jobs
# - Rails console
#
class ValueCalculatorService
  include ValueCalculator

  attr_reader :league

  def initialize(league)
    @league = league
  end

  # Execute value calculation with timing and error handling
  #
  # @return [Hash] Result with statistics or error
  def call
    start_time = Time.now
    result = recalculate_values(league)
    elapsed_time = (Time.now - start_time).round(2)

    result.merge(elapsed_time: elapsed_time)
  rescue StandardError => e
    Rails.logger.error("Value calculation failed for league #{league.id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    { error: e.message, count: 0 }
  end
end
