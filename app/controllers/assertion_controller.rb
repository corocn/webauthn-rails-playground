# frozen_string_literal: true


class AssertionController < ApplicationController

  # Request
  # {
  #   "username": "johndoe@example.com",
  #   "userVerification": "required"
  # }
  #
  # Response
  # {
  #   "status": "ok",
  #   "errorMessage": "",
  #   "challenge": "6283u0svT-YIF3pSolzkQHStwkJCaLKx",
  #   "timeout": 20000,
  #   "rpId": "https://example.com",
  #   "allowCredentials": [
  #     {
  #       "id": "m7xl_TkTcCe0WcXI2M-4ro9vJAuwcj4m",
  #       "type": "public-key"
  #     }
  #   ],
  #   "userVerification": "required"
  # }
  def options
    user = User.find_by!(username: params[:username])
    raise StandardError if !user.registered

    credential_options = build_credential_options
    credential_options[:allowCredentials] = user.credentials.map do |credential|
      { id: credential.cred_id, type: 'public-key' }
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
    render json: { status: 'failed', errorMessage: e.message }, status: :unprocessable_entity
  end

  # Request
  # {
  #   "id":"LFdoCFJTyB82ZzSJUHc-c72yraRc_1mPvGX8ToE8su39xX26Jcqd31LUkKOS36FIAWgWl6itMKqmDvruha6ywA",
  #   "rawId":"LFdoCFJTyB82ZzSJUHc-c72yraRc_1mPvGX8ToE8su39xX26Jcqd31LUkKOS36FIAWgWl6itMKqmDvruha6ywA",
  #   "response":{
  #     "authenticatorData":"SZYN5YgOjGh0NBcPZHZgW4_krrmihjLHmVzzuoMdl2MBAAAAAA",
  #     "signature":"MEYCIQCv7EqsBRtf2E4o_BjzZfBwNpP8fLjd5y6TUOLWt5l9DQIhANiYig9newAJZYTzG1i5lwP-YQk9uXFnnDaHnr2yCKXL",
  #     "userHandle":"",
  #     "clientDataJSON":"eyJjaGFsbGVuZ2UiOiJ4ZGowQ0JmWDY5MnFzQVRweTBrTmM4NTMzSmR2ZExVcHFZUDh3RFRYX1pFIiwiY2xpZW50RXh0ZW5zaW9ucyI6e30sImhhc2hBbGdvcml0aG0iOiJTSEEtMjU2Iiwib3JpZ2luIjoiaHR0cDovL2xvY2FsaG9zdDozMDAwIiwidHlwZSI6IndlYmF1dGhuLmdldCJ9"
  #   },
  #   "type":"public-key"
  # }
  #
  # Response
  # {
  #   "status": "ok",
  #   "errorMessage": ""
  # }
  def result
    auth_response = WebAuthn::AuthenticatorAssertionResponse.new(
      credential_id: str_to_bin(params[:id]),
      client_data_json: str_to_bin(params[:response][:clientDataJSON]),
      authenticator_data: str_to_bin(params[:response][:authenticatorData]),
      signature: str_to_bin(params[:response][:signature])
    )

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

  private

  def build_credential_options
    credential_options = WebAuthn.credential_request_options
    credential_options[:timeout] = 20_000
    credential_options[:userVerification] = params[:userVerification] || 'required'
    credential_options[:rpId] = webauthn_rpid
    credential_options
  end
end
