module Api
  class WebhooksController < ApplicationController
    skip_forgery_protection

    def call_status
      call = Call.find_by(call_sid: params[:CallSid])
      if call
        case params[:CallStatus]
        when "completed"
          call.update(status: :completed, duration: params[:CallDuration], completed_at: Time.current)
        when "failed"
          call.update(status: :failed, completed_at: Time.current)
        when "no-answer"
          call.update(status: :no_answer, completed_at: Time.current)
        when "busy"
          call.update(status: :busy, completed_at: Time.current)
        end
      end
      render json: { success: true }
    end
  end
end
