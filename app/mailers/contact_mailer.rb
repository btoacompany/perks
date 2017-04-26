class ContactMailer < ApplicationMailer
  default from: "support.prizy@btoa-company.com"

  def contact_mail(company, name, email, text)
    @company = company
    @name = name
    @email = email
    @text = text
    # mail to: @email,
    #      subject: "お問い合わせいただきありがとうございます。"
  end

  def btoa_mail(company, name, email, text)
    @company = company
    @name = name
    @email = email
    @text = text
    # mail to: "info@btoa-company.com",
    #      subject: "Prizyに関してお問い合わせがありました。"
  end
end
