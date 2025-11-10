class DashboardController < ApplicationController
  def index
    @stats = {
      total_numbers: PhoneNumber.count,
      total_calls: Call.count,
      completed: Call.completed.count,
      failed: Call.failed.count,
      no_answer: Call.no_answer.count
    }
    @recent_calls = Call.includes(:phone_number).order(created_at: :desc).limit(10)
  end
end
