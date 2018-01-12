class Admin::ContactsController < Admin::Base
  def index
  end

  def new
  end

  def create
    user_emails = User.where(company_id: @company.id, delete_flag: 0).pluck(:email)
    logger.debug(user_emails.count)
    data = {
      user_emails: user_emails,
      subject: params[:subject],
      description: params[:description]
    }
    DeliverContactMailJob.new.async.perform(data)

    flash[:notice] = "メール配信が完了しました"
    redirect_to new_admin_contact_path
  end
end
