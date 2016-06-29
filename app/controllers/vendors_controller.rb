#coding:utf-8

class VendorsController < ApplicationController
  def index
    @vendors = Vendor.where(:delete_flag => 0)
  end

  def create
    #do nothing
  end

  def create_complete
    vendor = Vendor.new
    vendor.save_record(params)
    redirect_to_index 
  end

  def edit
    @vendor = Vendor.find(params[:id])
  end
  
  def edit_complete
    vendor = Vendor.find(params[:id])
    vendor.save_record(params)

    item = Item.where(:vendor_id => vendor.id).update_all(:vendor_name => vendor.name)

    redirect_to_index 
  end

  def delete
    vendor = Vendor.find(params[:id])
    vendor.delete_record
    redirect_to_index 
  end

  def redirect_to_index
    redirect_to "/tools/vendors" 
  end
end
