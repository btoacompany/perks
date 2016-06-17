#coding:utf-8

class SuppliersController < ApplicationController
  def index
    @suppliers = Supplier.where(:delete_flag => 0)
  end

  def create
    #do nothing
  end

  def create_complete
    supplier = Supplier.new
    supplier.save_record(params)
    redirect_to_index 
  end

  def edit
    @supplier = Supplier.find(params[:id])
  end
  
  def edit_complete
    supplier = Supplier.find(params[:id])
    supplier.save_record(params)

    item = Item.where(:supplier_id => supplier.id).update_all(:supplier_name => supplier.name)

    redirect_to_index 
  end

  def delete
    supplier = Supplier.find(params[:id])
    supplier.delete_record
    redirect_to_index 
  end

  def redirect_to_index
    redirect_to "/tools/suppliers" 
  end
end
