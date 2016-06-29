#coding:utf-8

class ItemsController < ApplicationController
  before_filter :init

  def init 
    c = Category.new
    @categories = c.get_categories
  end

  def index
    @items = Item.where(:delete_flag => 0)
    if params[:cat].present?
      @items = Item.where(:delete_flag => 0, :category_id => params[:cat].to_i)
    end
  end

  def details
    @item = Item.find(params[:id])
  end

  def view
    @items = Item.where(:delete_flag => 0).order("id DESC")
  end

  def create
    @vendors = Vendor.where(:delete_flag => 0)
  end

  def create_complete
    params[:vendor_name] = Vendor.find(params[:vendor_id]).name
    item = Item.new
    item.save_record(params)
    redirect_to "/tools/items/create" 
    #redirect_to_index 
  end

  def edit
    @item = Item.find(params[:id])
    @vendors = Vendor.where(:delete_flag => 0)
  end
  
  def edit_complete
    params[:vendor_name] = Vendor.find(params[:vendor_id]).name
    item = Item.find(params[:id])
    item.save_record(params)
    redirect_to_index 
  end

  def delete
    item = Items.find(params[:id])
    item.delete_record
    redirect_to_index 
  end

  def redirect_to_index
    redirect_to "/tools/items" 
  end
end
