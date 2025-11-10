class TwilioService
  def initialize
    @account_sid = ENV["TWILIO_ACCOUNT_SID"]
    @auth_token = ENV["TWILIO_AUTH_TOKEN"]
    @from_number = ENV["TWILIO_PHONE_NUMBER"]
    @client = Twilio::REST::Client.new(@account_sid, @auth_token)
  end

  def make_call(to_number, voice_script)
    twiml = generate_twiml(voice_script)
    begin
      call = @client.calls.create(from: @from_number, to: to_number, twiml: twiml, record: true)
      { success: true, call_sid: call.sid, status: call.status }
    rescue Twilio::REST::TwilioError => e
      Rails.logger.error("Twilio: #{e.message}")
      { success: false, error: e.message }
    end
  end

  def get_call_details(call_sid)
    begin
      call = @client.calls(call_sid).fetch
      { status: call.status, duration: call.duration, direction: call.direction }
    rescue Twilio::REST::TwilioError => e
      { error: e.message }
    end
  end

  private

  def generate_twiml(voice_script)
    twiml = Twilio::TwiML::VoiceResponse.new do |response|
      response.say(message: voice_script, voice: "alice")
    end
    twiml.to_s
  end
end
