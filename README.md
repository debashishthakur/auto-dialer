# Autodialer

Rails 7.0 application for uploading phone numbers, dialing via Twilio, and tracking call logs.

## Setup

1. `bundle install`
2. `bin/rails db:prepare`
3. Copy `.env.example` to `.env` (or create `.env`) and fill in Twilio credentials.
4. `bin/rails server`

## Features

- Upload phone numbers manually or via CSV.
- Initiate single or bulk calls through Twilio.
- Track call logs and export them to CSV.
- Twilio webhook endpoint for call status updates.
