# config/initialize/raven.rb
require 'raven'
Raven.configure do |config|
  # config.environments = %w(production)
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  # config.dsn = ENV['SENTRY_RAILS_DNS']
end