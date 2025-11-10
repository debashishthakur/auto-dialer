class ProcessPhoneNumbersJob < ApplicationJob
    queue_as :default
  
    def perform(session_id, script)
      session = CallSession.find(session_id)
      pending_numbers = session.phone_numbers.where(status: :pending)
  
      pending_numbers.each_with_index do |phone_number, index|
        delay_seconds = index * 5
        MakeCallJob.set(wait: delay_seconds.seconds).perform_later(phone_number.id, script)
        phone_number.update(status: :processing)
      end
    end
  end
  