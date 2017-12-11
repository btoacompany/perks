class ReleaseArticleJob < ActiveJob::Base
  queue_as :default
  include SuckerPunch::Job

  def perform(*args)
    # Do something later
    args[0][:user_emails].each do |email|
      CompanyMailer.release_article(email, args[0][:subject], args[0][:description]).deliver_now
      sleep(0.8)
    end
  end
end
