#coding:utf-8

class TestsController < ApplicationController
  def index 
    @tests = Test.where(:delete_flag => 0)
  end

  def create
  end

  def create_complete
    #set_accounts
    test = Test.new
    test.save_record(params)
    redirect_to_index
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
