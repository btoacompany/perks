#coding:utf-8

class DeviceController < ApplicationController
  def register_ios
    token     = params[:token]
    email     = session[:email]
    #email = "s.karakama@btoa-company.com"

    user = User.find_by_email(email)
    user_id = user.id.to_s
    user.badge = 0
    user.save

    device = IosToken.where(:token => token).first

    if device.nil?
      endpoint = sns_create_endpoint(token, user_id)
      
      begin
        device = IosToken.new
        device.token = token
        device.user_id = user_id
        device.arn = endpoint[:endpoint_arn]

        device.save
      rescue Exception => e
        logger.debug e.message
      end
    else  
      unless user_id == device.user_id
        sns.delete_endpoint({ 
          :endpoint_arn => device.arn 
        });

        endpoint = sns_create_endpoint(token, user_id)

        device.user_id = user_id
        device.arn     = endpoint[:endpoint_arn]
        device.save
      end
    end

    render :layout => false
  end

  def unregister_ios
    token  = params[:token]

    sns = Aws::SNS::Client.new
    device = IosToken.where(:token => token).first

    unless device.nil?
      sns.delete_endpoint({ 
        :endpoint_arn => device.arn 
      });

      device.delete
    end
  end

  def sns_create_endpoint(token, user_id)
    sns = Aws::SNS::Client.new
    arn = "arn:aws:sns:ap-northeast-1:254772566290:app/APNS/Prizy.me.ios.prod"

    endpoint = sns.create_platform_endpoint(
      platform_application_arn: arn,
      token: token,
      attributes: { "UserId" => user_id }
    )

    return endpoint
  end
end
