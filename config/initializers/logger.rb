# frozen_string_literal: true

if Rails.env.production? || Rails.env.staging?
  require "le"
  Rails.logger = Le.new(ENV["LOGENTRIES_TOKEN"], local: true)
end
