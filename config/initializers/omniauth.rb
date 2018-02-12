OmniAuth.config.logger = Rails.logger
OmniAuth.config.on_failure = UsersController.action(:oauth_failure)

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV['FB_APP_ID'], ENV['FB_APP_SECRET'], {:scope => 'user_about_me', display: 'popup'}
  provider :slack, ENV['SLACK_API_KEY'], ENV['SLACK_API_SECRET'], {:scope => 'identity.basic'}
  #provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], {:scope => 'analytics.readonly'}
end
