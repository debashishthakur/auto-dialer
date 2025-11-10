class Api::V1::CallsController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :set_call_session, only: [:show, :start]
  
    def index
      @sessions = CallSession.all.order(created_at: :desc)
      render json: @sessions.map { |s| session_json(s) }
    end
  
    def create
      @session = CallSession.new(call_session_params)
      
      if @session.save
        if params[:phone_numbers].present?
          phone_numbers = params[:phone_numbers].is_a?(Array) ? params[:phone_numbers] : params[:phone_numbers].split(/[\r\n,;]/)
          phone_numbers.each do |num|
            formatted = PhoneNumber.format_to_e164(num.strip)
            if formatted.present?
              PhoneNumber.create!(number: formatted, call_session: @session, status: :pending)
            end
          end
          @session.update(total_numbers: @session.phone_numbers.count)
        end
        
        render json: session_json(@session), status: :created
      else
        render json: @session.errors, status: :unprocessable_entity
      end
    end
  
    def show
      render json: session_json(@session)
    end
  
    def start
      script = params[:call_script] || "Hello, this is an automated call."
      ProcessPhoneNumbersJob.perform_later(@session.id, script)
      render json: { status: 'started', message: 'Calls are being initiated' }
    end
  
    private
  
    def set_call_session
      @session = CallSession.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Session not found' }, status: :not_found
    end
  
    def call_session_params
      params.require(:call_session).permit(:name)
    end
  
    def session_json(session)
      {
        id: session.id,
        name: session.name,
        status: session.status,
        total_numbers: session.phone_numbers.count,
        completed_calls: session.call_logs.where(status: 'completed').count,
        failed_calls: session.call_logs.where(status: 'failed').count,
        created_at: session.created_at,
        updated_at: session.updated_at
      }
    end
  end
  