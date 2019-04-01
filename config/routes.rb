# frozen_string_literal: true

Rails.application.routes.draw do
  resources :attestation, only: [] do
    collection do
      post :options
      post :result
    end
  end

  resources :assertion, only: [] do
    collection do
      post :options
      post :result
    end
  end
end
