class CallLog < ApplicationRecord
    belongs_to :call_session
    belongs_to :phone_number
  
    validates :status, inclusion: { in: %w(initiated ringing answered completed failed no_answer) }
  
    enum status: { initiated: 0, ringing: 1, answered: 2, completed: 3, failed: 4, no_answer: 5 }
  
    def duration_in_seconds
      return 0 unless started_at && ended_at
      (ended_at - started_at).to_i
    end
  end
  