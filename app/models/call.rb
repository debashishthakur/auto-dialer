class Call < ApplicationRecord
  belongs_to :phone_number
  enum status: { pending: 0, in_progress: 1, completed: 2, failed: 3, no_answer: 4, busy: 5 }
  validates :phone_number, presence: true

  def duration_formatted
    return "0:00" if duration.nil? || duration.zero?

    minutes = duration / 60
    seconds = duration % 60
    "#{minutes}:#{seconds.to_s.rjust(2, "0")}"
  end
end
