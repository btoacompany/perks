require 'google/api_client'
#require 'signet'

# Google Analytics Client
class GaClient
  def initialize(
    application_name: 'Prizy Access Logs',
    application_version: '1.0.0'
  )
    @client = Google::APIClient.new(
      application_name: application_name,
      application_version: application_version
    )
  end

  def api
    @api ||= @client.discovered_api('analytics', 'v3')
  end

  def signing_key
    return if @signing_key

    keyfile = Rails.root.join('certificates', 'google_analytics.p12')
    passphrase = 'notasecret'

    @signing_key = Google::APIClient::KeyUtils.load_from_pkcs12(keyfile, passphrase)
  end

  def authorize!
    @client.authorization = Signet::OAuth2::Client.new(
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      audience: 'https://accounts.google.com/o/oauth2/token',
      scope: 'https://www.googleapis.com/auth/analytics.readonly',
      issuer: 'prizy-553@prizy-access-log-194918.iam.gserviceaccount.com',
      #issuer: 'support.prizy@btoa-company.com',
      signing_key: signing_key
    )
    @client.authorization.fetch_access_token!
  end

  def ga_page_view(date:)
    ga_id = 'ga:126759804'

    result = @client.execute(
      api_method: api.data.ga.get,
      parameters: {
        ids: ga_id,
        'start-date' => date.to_s,
        'end-date' => date.to_s,
        metrics: 'ga:pageviews',
        dimensions: 'ga:pagePath',
      }
    )
    body = JSON.parse(result.response.body)
    page_view = body['rows']

    page_view
  end
end