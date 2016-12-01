#coding:utf-8

class RewardsPrizy < ActiveRecord::Base
  self.table_name = "rewards_prizy"
  belongs_to :company
end
