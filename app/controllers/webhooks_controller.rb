class WebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token
  
    def status_callback
      call_sid = params['CallSid']
      status = params['CallStatus']
      duration = params['CallDuration'].to_i rescue 0
  
      call_log = CallLog.find_by(twilio_call_sid: call_sid)
      
      if call_log
        call_log.update(
          status: map_twilio_status(status),
          ended_at: Time.current,
          duration: duration
        )
      end
  
      render plain: 'OK'
    end
  
    private
  
    def map_twilio_status(twilio_status)
      case twilio_status
      when 'initiated'
        'initiated'
      when 'ringing'
        'ringing'
      when 'in-progress'
        'answered'
      when 'completed'
        'completed'
      when 'failed'
        'failed'
      when 'no-answer'
        'no_answer'
      else
        'initiated'
      end
    end
  end
  