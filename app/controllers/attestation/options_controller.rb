# frozen_string_literal: true

module Attestation
  class OptionsController < ApplicationController
    def create
      credential_options = build_credential_options

      payload = {
        username: params[:username],
        exp: Time.current.to_i + credential_options[:timeout] / 1000 + 5,
        nonce: bin_to_str(SecureRandom.random_bytes(32))
      }
      credential_options[:challenge] = Base64.urlsafe_encode64(::JWT.encode(payload, ENV['WEBAUTHN_SECRET'], 'HS256'))

      user = User.find_by(username: params[:username])

      if user.present? && !user.registered
        user.update!(nonce: payload[:nonce])
      else
        User.create!(username: params[:username], nonce: payload[:nonce])
      end

      render json: credential_options.merge(status: 'ok', errorMessage: '')
    rescue StandardError => e
      render json: { status: 'failed', errorMessage: e.message }, status: :unprocessable_entity
    end

    private

    def build_credential_options
      credential_options = ::WebAuthn.credential_creation_options
      credential_options[:user][:id] = bin_to_str(params[:username])
      credential_options[:user][:name] = params[:username]
      credential_options[:user][:displayName] = params[:displayName]
      credential_options[:timeout] = 20_000
      credential_options[:rp][:id] = webauthn_rpid
      credential_options[:rp][:name] = webauthn_rpid
      credential_options[:attestation] = params[:attestation] || 'none'

      if params[:authenticatorSelection]
        credential_options[:authenticatorSelection] = params[:authenticatorSelection].slice(
          :requireResidentKey, :authenticatorAttachment, :userVerification
        )
      end

      credential_options
    end
  end
end
