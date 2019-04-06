# frozen_string_literal: true

module Attestation
  class ResultsController < ApplicationController
    def create
      auth_response = build_auth_response

      jwt = Base64.urlsafe_decode64(auth_response.client_data.challenge)
      payload = ::JWT.decode(jwt, ENV['WEBAUTHN_SECRET'], true, algorithm: 'HS256')

      user = User.find_by!(username: payload[0]['username'])

      raise WebAuthn::VerificationError if user.nonce != payload[0]['nonce']

      user.update!(nonce: '')

      raise WebAuthn::VerificationError unless auth_response.verify(jwt, webauthn_origin)

      ActiveRecord::Base.transaction do
        credential = user.credentials.find_or_initialize_by(
          cred_id: Base64.strict_encode64(auth_response.credential.id)
        )
        credential.update!(
          public_key: Base64.strict_encode64(auth_response.credential.public_key)
        )
        user.update!(registered: true)
      end

      render json: { status: 'ok', errorMessage: '' }, status: :ok
    rescue StandardError => e
      render json: { status: 'failed', errorMessage: e.message }, status: :unprocessable_entity
    end

    private

    def build_auth_response
      WebAuthn::AuthenticatorAttestationResponse.new(
        attestation_object: str_to_bin(params[:response][:attestationObject]),
        client_data_json: str_to_bin(params[:response][:clientDataJSON])
      )
    end
  end
end
