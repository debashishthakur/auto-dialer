class AiPromptsController < ApplicationController
  def create
    service = AiPromptService.new(params[:prompt])
    render json: service.process
  end
end
