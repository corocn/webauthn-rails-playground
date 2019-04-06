# frozen_string_literal: true

module Assertion
  class OptionsController < ApplicationController
    def create
      user = User.find_by!(username: params[:username])
      raise StandardError if !user.registered

      credential_options = build_credential_options
      credential_options[:allowCredentials] = user.credentials.map do |credential|
        {id: credential.cred_id, type: 'public-key'}
      end

      payload = {
        username: params[:username],
        exp: Time.current.to_i + credential_options[:timeout] / 1000 + 5,
        nonce: bin_to_str(SecureRandom.random_bytes(32))
      }
      credential_options[:challenge] = Base64.urlsafe_encode64(::JWT.encode(payload, ENV['WEBAUTHN_SECRET'], 'HS256'))

      user.update!(nonce: payload[:nonce])

      render json: credential_options.merge(status: 'ok', errorMessage: '')
    rescue StandardError => e
      render json: {status: 'failed', errorMessage: e.message}, status: :unprocessable_entity
    end

    private

    def build_credential_options
      credential_options = WebAuthn.credential_request_options
      credential_options[:timeout] = 20_000
      credential_options[:userVerification] = params[:userVerification] || 'required'
      credential_options[:rpId] = webauthn_rpid
      credential_options
    end
  end
end
