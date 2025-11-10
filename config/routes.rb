Rails.application.routes.draw do
  root "dashboard#index"

  resources :phone_numbers
  resources :calls do
    collection do
      get :export_csv
      post :stop
    end
  end
  resources :ai_prompts, only: [:create]

  namespace :api do
    post "call_status", to: "webhooks#call_status"
  end
end
