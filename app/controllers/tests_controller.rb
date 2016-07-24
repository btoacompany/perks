#coding:utf-8
require 'aws-sdk'

class TestsController < ApplicationController
  def index 
    @tests = Test.where(:delete_flag => 0)
  end

  def create
  end

  def create_complete
    src = params[:img_src]
    s3 = Aws::S3::Resource.new
    obj = s3 .bucket("btoa-img").object("profile/#{src.original_filename}")
    obj.upload_file src.tempfile, {acl: 'public-read'}

    params[:img_src] = obj.public_url
    test = Test.new
    test.save_record(params)

    redirect_to_index
  end

  def save_img_to_s3(img_loc, folder_name, user_id)

  end


  def edit
    @test = Test.find(params[:id])
  end

  def edit_complete
    set_accounts
    
    test = Test.find(params[:id])
    test.save_record(params)
    redirect_to_index 
  end

  def set_accounts
    params[:accounts] = {
      tabelog:	  params[:tabelog],
      line_music: params[:line_music] 
    }
  end

  def redirect_to_index
    redirect_to "/tests" 
  end
end
