class PhoneNumbersController < ApplicationController
  def index
    @phone_numbers = PhoneNumber.order(created_at: :desc).limit(100)
    @stats = {
      total: PhoneNumber.count,
      active: PhoneNumber.active.count,
      inactive: PhoneNumber.inactive.count
    }
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
