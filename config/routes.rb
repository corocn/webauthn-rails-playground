# frozen_string_literal: true

Rails.application.routes.draw do
  resource :attestation, only: [], module: 'attestation' do
    resource :options, only: [:create]
    resource :result, only: [:create]
  end

  resource :assertion, only: [], module: 'assertion' do
    resource :options, only: [:create]
    resource :result, only: [:create]
  end
end
