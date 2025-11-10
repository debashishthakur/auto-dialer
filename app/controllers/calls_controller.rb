require "csv"

class CallsController < ApplicationController
  def index
    @calls = Call.includes(:phone_number).order(created_at: :desc).limit(100)
    @calls = @calls.where(status: params[:status]) if params[:status].present?
    @stats = {
      total: Call.count,
      completed: Call.completed.count,
      failed: Call.failed.count,
      no_answer: Call.no_answer.count,
      busy: Call.busy.count
    }
  end

  def show
    @call = Call.find(params[:id])
  end

  def create
    voice_script = params[:voice_script].presence || "Hello from Autodialer"
    service = TwilioService.new
    result = if params[:phone_number_id].present?
      phone_number = PhoneNumber.find_by(id: params[:phone_number_id])
      phone_number ? make_single_call(phone_number, voice_script, service) : { success: false, error: "Phone number not found" }
    else
      make_bulk_calls(PhoneNumber.active, voice_script, service)
    end

    respond_to do |format|
      format.json { render json: result }
      format.html do
        if result[:success]
          redirect_to calls_path, notice: result[:message] || "Dialing started"
        else
          redirect_to phone_numbers_path, alert: result[:error] || "Unable to start dialing"
        end
      end
    end
  end

  def stop
    Call.in_progress.update_all(status: :failed)
    render json: { success: true, message: "Stopped" }
  end

  def export_csv
    @calls = Call.includes(:phone_number).order(created_at: :desc)
    respond_to do |format|
      format.csv { send_data generate_csv(@calls), filename: "calls_#{Date.today}.csv" }
    end
  end

  private

  def make_single_call(phone_number, voice_script, service = TwilioService.new)
    result = service.make_call(phone_number.number, voice_script)
    Call.create!(phone_number: phone_number, call_sid: result[:call_sid], voice_script: voice_script, status: :in_progress, started_at: Time.current) if result[:success]
    result
  end

  def make_bulk_calls(phone_numbers, voice_script, service = TwilioService.new)
    numbers = phone_numbers.to_a
    return { success: false, error: "No active numbers available" } if numbers.empty?

    successes = 0
    failures = []

    numbers.each do |phone_number|
      result = make_single_call(phone_number, voice_script, service)
      if result[:success]
        successes += 1
      else
        failures << { number: phone_number.number, error: result[:error] }
      end
      sleep 1
    end

    if failures.empty?
      { success: true, message: "Dialing #{successes} numbers" }
    else
      { success: false, error: "Dialed #{successes} numbers, #{failures.size} failed", details: failures }
    end
  end

  def generate_csv(calls)
    CSV.generate do |csv|
      csv << ["Phone Number", "Status", "Duration", "Call SID", "Time"]
      calls.each do |call|
        csv << [
          call.phone_number.number,
          call.status,
          call.duration_formatted,
          call.call_sid,
          call.created_at.strftime("%Y-%m-%d %H:%M:%S")
        ]
      end
    end
  end
end
