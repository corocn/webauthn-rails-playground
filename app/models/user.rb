# frozen_string_literal: true

class User < ApplicationRecord
  has_many :credentials
  validates :username, presence: true, uniqueness: { case_sensitive: false }
end
