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

  def create
    @suppliers = Supplier.where(:delete_flag => 0)
  end

  def create_complete
    params[:supplier_name] = Supplier.find(params[:supplier_id]).name
    item = Item.new
    item.save_record(params)
    redirect_to "/tools/items/create" 
    #redirect_to_index 
  end

  def edit
    @item = Item.find(params[:id])
  end
  
  def edit_complete
    item = Items.find(params[:id])
    item.save_record(params)
    redirect_to_index 
  end

  def delete
    item = Items.find(params[:id])
    item.delete_record
    redirect_to_index 
  end

  def redirect_to_index
    redirect_to "/items" 
  end
end
