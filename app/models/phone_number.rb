class PhoneNumber < ApplicationRecord
  validates :number, presence: true, uniqueness: true
  validates :number, format: { with: /\A\+\d{10,15}\z/, message: "must be valid format" }
  has_many :calls, dependent: :destroy
  enum status: { active: 0, inactive: 1, invalid_number: 2 }

  def self.import_from_csv(file)
    require "csv"
    CSV.foreach(file.path, headers: true) do |row|
      number = row["phone_number"]&.strip
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
    clean = number.gsub(/[^0-9+]/, "")
    clean = clean.gsub(/^0/, "+1")
    clean = "+1#{clean}" if clean.length == 10 && !clean.start_with?("+")
    clean
  end
end
