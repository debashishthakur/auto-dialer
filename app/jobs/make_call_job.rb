class MakeCallJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 3
  
    def perform(phone_number_id, script)
      phone_number = PhoneNumber.find(phone_number_id)
      session = phone_number.call_session
  
      begin
        call = Twilio::REST::Client.new.calls.create(
          from: ENV['TWILIO_PHONE_NUMBER'],
          to: phone_number.number,
          url: "https://example.com/api/v1/twilio/voice",
          status_callback: "https://example.com/webhooks/twilio/status",
          status_callback_event: ['initiated', 'ringing', 'answered', 'completed']
        )
  
        call_log = CallLog.create!(
          call_session: session,
          phone_number: phone_number,
          twilio_call_sid: call.sid,
          status: :initiated,
          started_at: Time.current
        )
  
        phone_number.update(status: :completed, last_called_at: Time.current)
      rescue => e
        phone_number.update(status: :failed, attempts: phone_number.attempts + 1)
        
        CallLog.create!(
          call_session: session,
          phone_number: phone_number,
          status: :failed,
          error_message: e.message,
          started_at: Time.current,
          ended_at: Time.current
        )
  
        raise e
      end
    end
  end
  