# frozen_string_literal: true

module Assertion
  class ResultsController < ApplicationController
    def create
      auth_response = build_auth_response

      jwt = Base64.urlsafe_decode64(auth_response.client_data.challenge)
      payload = ::JWT.decode(jwt, ENV['WEBAUTHN_SECRET'], true, algorithm: 'HS256')

      user = User.find_by!(username: payload[0]['username'])

      allowed_credentials = user.credentials.map do |credential|
        {
          id: str_to_bin(credential.cred_id),
          public_key: str_to_bin(credential.public_key)
        }
      end

      raise WebAuthn::VerificationError if user.nonce != payload[0]['nonce']

      user.update!(nonce: '')

      render json: { status: 'failed' }, status: :forbidden unless auth_response.verify(
        jwt,
        webauthn_origin,
        allowed_credentials: allowed_credentials
      )

      render json: { status: 'ok', errorMessage: '' }, status: :ok
    rescue StandardError => e
      render json: { status: 'failed', errorMessage: e.message }, status: :forbidden
    end

    def build_auth_response
      WebAuthn::AuthenticatorAssertionResponse.new(
        credential_id: str_to_bin(params[:id]),
        client_data_json: str_to_bin(params[:response][:clientDataJSON]),
        authenticator_data: str_to_bin(params[:response][:authenticatorData]),
        signature: str_to_bin(params[:response][:signature])
      )
    end
  end
end
