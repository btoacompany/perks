class ChangeVoteResultResultColumnTypetoInteger < ActiveRecord::Migration
  def change
    def up
      change_column :vote_results, :result, :integer, null: false, default: 0
    end

    def down
      change_column :vote_results, result, :text
    end
  end
end

