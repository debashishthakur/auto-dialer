class CallSession < ApplicationRecord
    has_many :phone_numbers, dependent: :destroy
    has_many :call_logs, dependent: :destroy
  
    validates :name, presence: true
  
    enum status: { pending: 0, in_progress: 1, completed: 2 }
  
    def statistics
      {
        total_numbers: phone_numbers.count,
        completed_calls: call_logs.where(status: 'completed').count,
        failed_calls: call_logs.where(status: 'failed').count,
        success_rate: calculate_success_rate
      }
    end
  
    private
  
    def calculate_success_rate
      total = call_logs.count
      return 0 if total.zero?
      (call_logs.where(status: 'completed').count.to_f / total * 100).round(2)
    end
  end
  