# 🤖 SIMPLIFIED AI PROMPT - For Terminal/IDE

**Paste this into Cursor, GitHub Copilot, Claude in your editor, etc.**

---

## PASTE THIS EXACT PROMPT:

```
You are an expert Ruby on Rails developer. Create a complete Autodialer Rails app.

## SPECS
- Ruby: 3.4.4, Rails: 7.0.0, Database: SQLite
- Twilio API integration for automated calling
- Features: Upload phone numbers, make calls, track logs

## DO THIS FIRST
1. Fix config/application.rb: 
   - Change "config.load_defaults 7.1" to "config.load_defaults 7.0"
   - Remove "config.autoload_lib" line
2. Replace Gemfile with SQLite version (replace pg with sqlite3)
3. Fix config/database.yml for SQLite

## GEMFILE (Replace entire Gemfile):
```ruby
source "https://rubygems.org"
ruby "3.4.4"
gem "rails", "~> 7.0.0"
gem "sqlite3", "~> 1.4"
gem "puma", "~> 5.0"
gem "bootsnap", ">= 1.4.4", require: false
gem "sass-rails", ">= 6"
gem "webpacker", "~> 5.0"
gem "jbuilder", "~> 2.7"
gem "redis", "~> 4.0"
gem "bcrypt", "~> 3.1.7"
gem "csv"
gem "twilio-ruby", "~> 6.0"
gem "dotenv-rails", groups: [:development, :test]
gem "kaminari", "~> 1.2"
gem "httparty", "~> 0.21.0"
gem "json", "~> 2.6"
group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
end
group :development do
  gem "web-console", ">= 4.1.0"
  gem "listen", "~> 3.3"
end
group :test do
  gem "capybara", ">= 3.26"
  gem "selenium-webdriver"
end
```

## MODELS

### app/models/phone_number.rb
```ruby
class PhoneNumber < ApplicationRecord
  validates :number, presence: true, uniqueness: true
  validates :number, format: { with: /\A\+\d{10,15}\z/, message: "must be valid format" }
  has_many :calls, dependent: :destroy
  enum status: { active: 0, inactive: 1, invalid: 2 }
  
  def self.import_from_csv(file)
    require 'csv'
    CSV.foreach(file.path, headers: true) do |row|
      number = row['phone_number']&.strip
      next if number.blank?
      number = normalize_number(number)
      begin
        PhoneNumber.find_or_create_by(number: number)
      rescue => e
        Rails.logger.error("Error: #{e.message}")
      end
    end
  end
  
  def self.normalize_number(number)
    clean = number.gsub(/[^0-9+]/, '')
    clean = clean.gsub(/^0/, '+1')
    clean = "+1#{clean}" if clean.length == 10 && !clean.start_with?('+')
    clean
  end
end
```

### app/models/call.rb
```ruby
class Call < ApplicationRecord
  belongs_to :phone_number
  enum status: { pending: 0, in_progress: 1, completed: 2, failed: 3, no_answer: 4, busy: 5 }
  validates :phone_number, presence: true
  
  def duration_formatted
    return "0:00" if duration.nil? || duration.zero?
    minutes = duration / 60
    seconds = duration % 60
    "#{minutes}:#{seconds.to_s.rjust(2, '0')}"
  end
end
```

## SERVICES

### app/services/twilio_service.rb
```ruby
class TwilioService
  def initialize
    @account_sid = ENV['TWILIO_ACCOUNT_SID']
    @auth_token = ENV['TWILIO_AUTH_TOKEN']
    @from_number = ENV['TWILIO_PHONE_NUMBER']
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
      response.say(message: voice_script, voice: 'alice')
    end
    twiml.to_s
  end
end
```

### app/services/ai_prompt_service.rb
```ruby
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
    phone_number ? { success: true, action: :call_single, phone_number: phone_number, message: "Calling..." } : { success: false, message: "Number not found" }
  end
  
  def initiate_bulk_calls
    count = PhoneNumber.active.count
    { success: true, action: :call_bulk, count: count, message: "Starting..." }
  end
  
  def stop_calls
    { success: true, action: :stop, message: "Stopped" }
  end
  
  def show_statistics
    { success: true, action: :stats, data: { total_numbers: PhoneNumber.count, total_calls: Call.count, completed: Call.completed.count, failed: Call.failed.count }, message: "Stats" }
  end
end
```

## CONTROLLERS

### app/controllers/dashboard_controller.rb
```ruby
class DashboardController < ApplicationController
  def index
    @stats = { total_numbers: PhoneNumber.count, total_calls: Call.count, completed: Call.completed.count, failed: Call.failed.count, no_answer: Call.no_answer.count }
    @recent_calls = Call.includes(:phone_number).order(created_at: :desc).limit(10)
  end
end
```

### app/controllers/phone_numbers_controller.rb
```ruby
class PhoneNumbersController < ApplicationController
  def index
    @phone_numbers = PhoneNumber.all.order(created_at: :desc).limit(100)
    @stats = { total: PhoneNumber.count, active: PhoneNumber.active.count, inactive: PhoneNumber.inactive.count }
  end
  
  def new
    @phone_number = PhoneNumber.new
  end
  
  def create
    if params[:phone_numbers].present?
      numbers = params[:phone_numbers].split("\n").map(&:strip).reject(&:blank?)
      results = import_numbers(numbers)
      flash[:success] = "#{results[:success]} imported"
    elsif params[:csv_file].present?
      PhoneNumber.import_from_csv(params[:csv_file])
      flash[:success] = "CSV imported"
    end
    redirect_to phone_numbers_path
  end
  
  def destroy
    PhoneNumber.find(params[:id]).destroy
    redirect_to phone_numbers_path
  end
  
  private
  
  def import_numbers(numbers)
    success = 0
    numbers.each do |number|
      normalized = PhoneNumber.normalize_number(number)
      success += 1 if PhoneNumber.create(number: normalized)
    end
    { success: success, failed: numbers.count - success }
  end
end
```

### app/controllers/calls_controller.rb
```ruby
class CallsController < ApplicationController
  def index
    @calls = Call.includes(:phone_number).order(created_at: :desc).limit(100)
    @calls = @calls.where(status: params[:status]) if params[:status].present?
    @stats = { total: Call.count, completed: Call.completed.count, failed: Call.failed.count, no_answer: Call.no_answer.count, busy: Call.busy.count }
  end
  
  def show
    @call = Call.find(params[:id])
  end
  
  def create
    voice_script = params[:voice_script] || "Hello from Autodialer"
    if params[:phone_number_id].present?
      result = make_single_call(PhoneNumber.find(params[:phone_number_id]), voice_script)
    else
      result = make_bulk_calls(PhoneNumber.active.limit(100), voice_script)
    end
    render json: result
  end
  
  def stop
    Call.in_progress.update_all(status: :failed)
    render json: { success: true, message: 'Stopped' }
  end
  
  def export_csv
    @calls = Call.includes(:phone_number).order(created_at: :desc)
    respond_to do |format|
      format.csv { send_data generate_csv(@calls), filename: "calls_#{Date.today}.csv" }
    end
  end
  
  private
  
  def make_single_call(phone_number, voice_script)
    service = TwilioService.new
    result = service.make_call(phone_number.number, voice_script)
    if result[:success]
      Call.create!(phone_number: phone_number, call_sid: result[:call_sid], voice_script: voice_script, status: :in_progress, started_at: Time.current)
    end
    result
  end
  
  def make_bulk_calls(phone_numbers, voice_script)
    service = TwilioService.new
    phone_numbers.each { |phone_number| make_single_call(phone_number, voice_script); sleep 1 }
    { success: true, message: "Bulk calling started" }
  end
  
  def generate_csv(calls)
    CSV.generate do |csv|
      csv << ['Phone Number', 'Status', 'Duration', 'Call SID', 'Time']
      calls.each { |call| csv << [call.phone_number.number, call.status, call.duration_formatted, call.call_sid, call.created_at.strftime('%Y-%m-%d %H:%M:%S')] }
    end
  end
end
```

### app/controllers/ai_prompts_controller.rb
```ruby
class AiPromptsController < ApplicationController
  def create
    service = AiPromptService.new(params[:prompt])
    render json: service.process
  end
end
```

### app/controllers/api/webhooks_controller.rb
```ruby
module Api
  class WebhooksController < ApplicationController
    skip_forgery_protection
    
    def call_status
      call = Call.find_by(call_sid: params[:CallSid])
      if call
        case params[:CallStatus]
        when 'completed'
          call.update(status: :completed, duration: params[:CallDuration], completed_at: Time.current)
        when 'failed'
          call.update(status: :failed, completed_at: Time.current)
        when 'no-answer'
          call.update(status: :no_answer, completed_at: Time.current)
        when 'busy'
          call.update(status: :busy, completed_at: Time.current)
        end
      end
      render json: { success: true }
    end
  end
end
```

## ROUTES (Replace config/routes.rb)
```ruby
Rails.application.routes.draw do
  root 'dashboard#index'
  resources :phone_numbers
  resources :calls do
    collection do
      get :export_csv
      post :stop
    end
  end
  resources :ai_prompts, only: [:create]
  namespace :api do
    post 'call_status', to: 'webhooks#call_status'
  end
end
```

## INITIALIZER (Create config/initializers/twilio.rb)
```ruby
require 'twilio-ruby'
Twilio.configure do |config|
  config.account_sid = ENV['TWILIO_ACCOUNT_SID']
  config.auth_token = ENV['TWILIO_AUTH_TOKEN']
end
```

## VIEWS (Minimal HTML/ERB with inline CSS)

### app/views/layouts/application.html.erb
```erb
<!DOCTYPE html>
<html>
  <head>
    <title>Autodialer</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      body { font-family: sans-serif; background: #f3f4f6; }
      .sidebar { width: 250px; background: #4F46E5; color: white; padding: 20px; height: 100vh; position: fixed; left: 0; top: 0; }
      .main { margin-left: 250px; padding: 20px; }
      .card { background: white; padding: 20px; border-radius: 8px; margin: 10px 0; }
      .nav-link { display: block; color: white; text-decoration: none; padding: 10px; margin: 5px 0; border-radius: 5px; }
      .nav-link:hover { background: rgba(255,255,255,0.1); }
      .btn { padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; }
      .btn-primary { background: #4F46E5; color: white; }
      table { width: 100%; border-collapse: collapse; }
      th, td { padding: 12px; text-align: left; border-bottom: 1px solid #e5e7eb; }
      th { background: #f3f4f6; }
      .badge { padding: 4px 8px; border-radius: 3px; font-size: 12px; }
      .badge-completed { background: #d1fae5; color: #065f46; }
      .badge-failed { background: #fee2e2; color: #991b1b; }
      textarea, input { width: 100%; padding: 10px; margin: 5px 0; border: 1px solid #d1d5db; border-radius: 5px; }
      .alert { padding: 10px; margin: 10px 0; border-radius: 5px; }
      .alert-success { background: #d1fae5; color: #065f46; }
    </style>
  </head>
  <body>
    <div class="sidebar">
      <h2>📞 Autodialer</h2>
      <%= link_to "🏠 Dashboard", root_path, class: "nav-link" %>
      <%= link_to "📱 Phone Numbers", phone_numbers_path, class: "nav-link" %>
      <%= link_to "📞 Call Logs", calls_path, class: "nav-link" %>
    </div>
    <div class="main">
      <% if notice %><div class="alert alert-success"><%= notice %></div><% end %>
      <% if alert %><div class="alert"><%= alert %></div><% end %>
      <%= yield %>
    </div>
  </body>
</html>
```

### app/views/dashboard/index.html.erb
```erb
<h1>Dashboard</h1>
<div>
  <div class="card" style="display: inline-block; width: 23%; margin: 1%;">
    <div>Total Numbers</div>
    <div style="font-size: 32px; font-weight: bold;"><%= @stats[:total_numbers] %></div>
  </div>
  <div class="card" style="display: inline-block; width: 23%; margin: 1%;">
    <div>Total Calls</div>
    <div style="font-size: 32px; font-weight: bold;"><%= @stats[:total_calls] %></div>
  </div>
  <div class="card" style="display: inline-block; width: 23%; margin: 1%;">
    <div>Completed</div>
    <div style="font-size: 32px; font-weight: bold; color: #10b981;"><%= @stats[:completed] %></div>
  </div>
  <div class="card" style="display: inline-block; width: 23%; margin: 1%;">
    <div>Failed</div>
    <div style="font-size: 32px; font-weight: bold; color: #ef4444;"><%= @stats[:failed] %></div>
  </div>
</div>
<div class="card">
  <h2>Recent Calls</h2>
  <table>
    <thead>
      <tr>
        <th>Phone Number</th>
        <th>Status</th>
        <th>Time</th>
      </tr>
    </thead>
    <tbody>
      <% @recent_calls.each do |call| %>
        <tr>
          <td><%= call.phone_number.number %></td>
          <td><span class="badge badge-<%= call.status %>"><%= call.status.titleize %></span></td>
          <td><%= call.created_at.strftime('%Y-%m-%d %H:%M') %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

### app/views/phone_numbers/index.html.erb
```erb
<h1 style="display: flex; justify-content: space-between;">
  📱 Phone Numbers
  <%= link_to "➕ Upload", new_phone_number_path, class: "btn btn-primary" %>
</h1>
<div class="card">
  <p>Total: <%= @stats[:total] %> | Active: <%= @stats[:active] %></p>
</div>
<div class="card">
  <table>
    <thead>
      <tr>
        <th>Phone Number</th>
        <th>Status</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <% @phone_numbers.each do |number| %>
        <tr>
          <td><%= number.number %></td>
          <td><span class="badge"><%= number.status.titleize %></span></td>
          <td><%= link_to "Delete", phone_number_path(number), method: :delete, data: { confirm: "Sure?" } %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

### app/views/phone_numbers/new.html.erb
```erb
<h1>📱 Upload Phone Numbers</h1>
<div class="card">
  <%= form_with url: phone_numbers_path, method: :post do |f| %>
    <h3>Copy & Paste Numbers (one per line: +1XXXXXXXXXX)</h3>
    <%= text_area_tag :phone_numbers, nil, rows: 10, placeholder: "+12025551234\n+12025551235" %>
    <h3 style="margin-top: 20px;">OR Upload CSV</h3>
    <%= file_field_tag :csv_file, accept: ".csv" %>
    <div style="margin-top: 20px;">
      <%= link_to "Cancel", phone_numbers_path, class: "btn", style: "background: #e5e7eb;" %>
      <%= submit_tag "Import", class: "btn btn-primary" %>
    </div>
  <% end %>
</div>
```

### app/views/calls/index.html.erb
```erb
<h1 style="display: flex; justify-content: space-between;">
  📞 Call Logs
  <%= link_to "Export CSV", export_csv_calls_path(format: :csv), class: "btn btn-primary" %>
</h1>
<div class="card">
  <p>Total: <%= @stats[:total] %> | Completed: <%= @stats[:completed] %> | Failed: <%= @stats[:failed] %></p>
</div>
<div class="card">
  <table>
    <thead>
      <tr>
        <th>Phone Number</th>
        <th>Status</th>
        <th>Call SID</th>
        <th>Time</th>
      </tr>
    </thead>
    <tbody>
      <% @calls.each do |call| %>
        <tr>
          <td><%= call.phone_number.number %></td>
          <td><span class="badge badge-<%= call.status %>"><%= call.status.titleize %></span></td>
          <td><code><%= call.call_sid %></code></td>
          <td><%= call.created_at.strftime('%Y-%m-%d %H:%M') %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

## ENVIRONMENT (.env file - CREATE)
```
TWILIO_ACCOUNT_SID=AC56c2cf328b79250ae75c9752ad479dda
TWILIO_AUTH_TOKEN=d3fcedf6230fe37fca31d810d88a95fd
TWILIO_PHONE_NUMBER=+12173758455
GEMINI_API_KEY=AIzaSyBocKzSE1tR3gFDFsQmLK1Mqn3Be3N8eQg
RAILS_ENV=development
```

## TESTING
After creating all files, run:
```bash
bundle install
rails db:create
rails generate model PhoneNumber number:string status:integer notes:text
rails generate model Call phone_number:references call_sid:string status:integer duration:integer recording_url:text voice_script:text started_at:datetime completed_at:datetime
rails db:migrate
rails server
# Visit http://localhost:3000
```

Verify:
- Dashboard loads
- Phone Numbers page works
- Can upload +12025551234
- Call Logs page loads
- No errors

Report success when all files created and app starts without errors.
```

---

## ✅ HOW TO USE

1. **Copy everything in the code block above**
2. **Open Cursor, GitHub Copilot, or Claude in your IDE**
3. **Paste the prompt**
4. **Click "Create" / "Generate" / "Run"**
5. **The AI will create all files automatically**

---

## 🚀 AFTER AI FINISHES

```bash
bundle install
rails db:create
rails db:migrate
rails server

# Visit: http://localhost:3000
# Test the app
# Then push to GitHub and deploy to Fly.io!
```

---

**This prompt is self-contained and complete!** 🎉
