class ReleaseArticleJob < ActiveJob::Base
  queue_as :default
  include SuckerPunch::Job

  def perform(*args)
    # Do something later
    CompanyMailer.release_article(args[0][:user_emails], args[0][:subject], args[0][:description]).deliver_now
    rescue => e
    if e
      flash[:notice] = "#{e}"
      redirect_to company_articles_path
    end
  end
end
