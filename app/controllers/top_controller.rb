#coding:utf-8

class TopController < ApplicationController
  before_filter :init

  def init 
    c = Category.new
    @categories = c.get_categories
  end

  def index
    @items = {} 
    @categories.each do | id, val |
      @items[id] = Item.where(:category_id => id.to_i, :delete_flag => 0).order("id DESC").limit(2)
    end
  end
end
