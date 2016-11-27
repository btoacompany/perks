#coding:utf-8

class DeviceController < ApplicationController
  def register
    arn = "arn:aws:sns:ap-northeast-1:254772566290:app/APNS/Prizy.me.ios.prod"

    sns = Aws::SNS::Client.new
    endpoint = sns.create_platform_endpoint(
      platform_application_arn: arn,
      token: params[:token],
      attributes: { "UserId" => session[:id] }
    )

    device = IosToken.new
    device.save(
      :token	=> params[:token],
      :user_id	=> session[:id],
      :arn	=> endpoint[:endpoint_arn] 
    )

    render :layout => false
  end

  def unregister
  end
end
