# frozen_string_literal: true

class AttestationController < ApplicationController

  # Request
  # {
  #   "username": "johndoe@example.com",
  #   "displayName": "John Doe",
  #   "authenticatorSelection": {
  #     "requireResidentKey": false,
  #     "authenticatorAttachment": "cross-platform",
  #     "userVerification": "preferred"
  #   },
  #   "attestation": "direct"
  # }
  #
  # Response
  # {
  #   "status": "ok",
  #   "errorMessage": "",
  #   "rp": {
  #     "name": "Example Corporation"
  #   },
  #   "user": {
  #     "id": "S3932ee31vKEC0JtJMIQ",
  #     "name": "johndoe@example.com",
  #     "displayName": "John Doe"
  #   },
  #
  #   "challenge": "uhUjPNlZfvn7onwuhNdsLPkkE5Fv-lUN",
  #   "pubKeyCredParams": [
  #     {
  #       "type": "public-key",
  #       "alg": -7
  #     }
  #   ],
  #   "timeout": 10000,
  #   "excludeCredentials": [
  #     {
  #       "type": "public-key",
  #       "id": "opQf1WmYAa5aupUKJIQp"
  #     }
  #   ],
  #   "authenticatorSelection": {
  #     "requireResidentKey": false,
  #     "authenticatorAttachment": "cross-platform",
  #     "userVerification": "preferred"
  #   },
  #   "attestation": "direct"
  # }
  def options
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

  # Request
  # {
  #   "id": "LFdoCFJTyB82ZzSJUHc-c72yraRc_1mPvGX8ToE8su39xX26Jcqd31LUkKOS36FIAWgWl6itMKqmDvruha6ywA",
  #   "rawId": "LFdoCFJTyB82ZzSJUHc-c72yraRc_1mPvGX8ToE8su39xX26Jcqd31LUkKOS36FIAWgWl6itMKqmDvruha6ywA",
  #   "response": {
  #     "clientDataJSON": "eyJjaGFsbGVuZ2UiOiJOeHlab3B3VktiRmw3RW5uTWFlXzVGbmlyN1FKN1FXcDFVRlVLakZIbGZrIiwiY2xpZW50RXh0ZW5zaW9ucyI6e30sImhhc2hBbGdvcml0aG0iOiJTSEEtMjU2Iiwib3JpZ2luIjoiaHR0cDovL2xvY2FsaG9zdDozMDAwIiwidHlwZSI6IndlYmF1dGhuLmNyZWF0ZSJ9",
  #     "attestationObject": "o2NmbXRoZmlkby11MmZnYXR0U3RtdKJjc2lnWEcwRQIgVzzvX3Nyp_g9j9f2B-tPWy6puW01aZHI8RXjwqfDjtQCIQDLsdniGPO9iKr7tdgVV-FnBYhvzlZLG3u28rVt10YXfGN4NWOBWQJOMIICSjCCATKgAwIBAgIEVxb3wDANBgkqhkiG9w0BAQsFADAuMSwwKgYDVQQDEyNZdWJpY28gVTJGIFJvb3QgQ0EgU2VyaWFsIDQ1NzIwMDYzMTAgFw0xNDA4MDEwMDAwMDBaGA8yMDUwMDkwNDAwMDAwMFowLDEqMCgGA1UEAwwhWXViaWNvIFUyRiBFRSBTZXJpYWwgMjUwNTY5MjI2MTc2MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEZNkcVNbZV43TsGB4TEY21UijmDqvNSfO6y3G4ytnnjP86ehjFK28-FdSGy9MSZ-Ur3BVZb4iGVsptk5NrQ3QYqM7MDkwIgYJKwYBBAGCxAoCBBUxLjMuNi4xLjQuMS40MTQ4Mi4xLjUwEwYLKwYBBAGC5RwCAQEEBAMCBSAwDQYJKoZIhvcNAQELBQADggEBAHibGMqbpNt2IOL4i4z96VEmbSoid9Xj--m2jJqg6RpqSOp1TO8L3lmEA22uf4uj_eZLUXYEw6EbLm11TUo3Ge-odpMPoODzBj9aTKC8oDFPfwWj6l1O3ZHTSma1XVyPqG4A579f3YAjfrPbgj404xJns0mqx5wkpxKlnoBKqo1rqSUmonencd4xanO_PHEfxU0iZif615Xk9E4bcANPCfz-OLfeKXiT-1msixwzz8XGvl2OTMJ_Sh9G9vhE-HjAcovcHfumcdoQh_WM445Za6Pyn9BZQV3FCqMviRR809sIATfU5lu86wu_5UGIGI7MFDEYeVGSqzpzh6mlcn8QSIZoYXV0aERhdGFYxEmWDeWIDoxodDQXD2R2YFuP5K65ooYyx5lc87qDHZdjQQAAAAAAAAAAAAAAAAAAAAAAAAAAAEAsV2gIUlPIHzZnNIlQdz5zvbKtpFz_WY-8ZfxOgTyy7f3Ffbolyp3fUtSQo5LfoUgBaBaXqK0wqqYO-u6FrrLApQECAyYgASFYIPr9-YH8DuBsOnaI3KJa0a39hyxh9LDtHErNvfQSyxQsIlgg4rAuQQ5uy4VXGFbkiAt0uwgJJodp-DymkoBcrGsLtkI"
  #   },
  #   "type": "public-key"
  # }
  #
  # Response
  # {
  #     "status": "ok",
  #     "errorMessage": ""
  # }
  def result
    auth_response = WebAuthn::AuthenticatorAttestationResponse.new(
      attestation_object: str_to_bin(params[:response][:attestationObject]),
      client_data_json: str_to_bin(params[:response][:clientDataJSON])
    )
    jwt = Base64.urlsafe_decode64(auth_response.client_data.challenge)
    payload = ::JWT.decode(jwt, ENV['WEBAUTHN_SECRET'], true, algorithm: 'HS256')

    user = User.find_by!(username: payload[0]['username'])

    raise WebAuthn::VerificationError if user.nonce != payload[0]['nonce']

    user.update!(nonce: '')

    raise WebAuthn::VerificationError unless auth_response.verify(jwt, webauthn_origin)

    ActiveRecord::Base.transaction do
      credential = user.credentials.find_or_initialize_by(
        cred_id: Base64::strict_encode64(auth_response.credential.id)
      )
      credential.update!(
        public_key: Base64::strict_encode64(auth_response.credential.public_key)
      )
      user.update!(registered: true)
    end

    render json: { status: 'ok', errorMessage: '' }, status: :ok
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
