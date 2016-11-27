#coding:utf-8

class DeviceController < ApplicationController
  def register_ios
    params[:token]  = "5cc3647072ee117c9e53e9942f62ca82c40b97014874eb8eba4f646ddcbd0296"
    email    = "s.karakama@btoa-company.com"
    #email = session[:email]

    user_id = User.find_by_email(email).id
    arn = "arn:aws:sns:ap-northeast-1:254772566290:app/APNS/Prizy.me.ios.prod"

    sns = Aws::SNS::Client.new
    endpoint = sns.create_platform_endpoint(
      platform_application_arn: arn,
      token: params[:token],
      attributes: { "UserId" => user_id }
    )

    begin
      device = IosToken.new
      device.save(
	:token	=> params[:token],
	:user_id	=> user_id,
	:arn	=> endpoint[:endpoint_arn] 
      )
    rescue Exception => e
      logger.debug e.message
    end

    render :layout => false
  end

  def unregister_ios
  end
end
