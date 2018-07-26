class AddIsDeliveredToVoteTable < ActiveRecord::Migration
  def change
    add_column :votes, :is_delivered, :boolean, default: false, null: false
  end
end
