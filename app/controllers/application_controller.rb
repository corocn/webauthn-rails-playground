# frozen_string_literal: true

class ApplicationController < ActionController::API
  def webauthn_origin
    return ENV['WEBAUTHN_ORIGIN'] if Rails.env.production?

    request.headers['origin']
  end

  def webauthn_rpid
    URI.parse(webauthn_origin).host
  end

  def str_to_bin(str)
    Base64.urlsafe_decode64(str)
  end

  def bin_to_str(bin)
    Base64.urlsafe_encode64(bin, padding: false)
  end
end
