class AiPromptService
  def initialize(user_prompt)
    @prompt = user_prompt.downcase.strip
  end

  def process
    case @prompt
    when /call\s+\+?\d{10}/
      extract_and_call_single_number
    when /call all/, /start calling/, /begin calls/
      initiate_bulk_calls
    when /stop/, /pause/, /halt/
      stop_calls
    when /stats/, /statistics/, /show/
      show_statistics
    else
      { success: false, message: "Unknown command" }
    end
  end

  private

  def extract_and_call_single_number
    match = @prompt.match(/\+?\d{10,}/)
    return { success: false, message: "No number found" } unless match

    number = match[0]
    number = "+1#{number}" if number.length == 10
    phone_number = PhoneNumber.find_by(number: number)
    if phone_number
      { success: true, action: :call_single, phone_number: phone_number, message: "Calling..." }
    else
      { success: false, message: "Number not found" }
    end
  end

  def initiate_bulk_calls
    count = PhoneNumber.active.count
    { success: true, action: :call_bulk, count: count, message: "Starting..." }
  end

  def stop_calls
    { success: true, action: :stop, message: "Stopped" }
  end

  def show_statistics
    {
      success: true,
      action: :stats,
      data: {
        total_numbers: PhoneNumber.count,
        total_calls: Call.count,
        completed: Call.completed.count,
        failed: Call.failed.count
      },
      message: "Stats"
    }
  end
end
