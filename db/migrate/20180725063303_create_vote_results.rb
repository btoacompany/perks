class CreateVoteResults < ActiveRecord::Migration
  def change
    create_table :vote_results do |t|
      t.references :company
      t.references :user
      t.integer :team_id
      t.integer :department_id
      t.references :vote
      t.integer :result, null: false, default: 0

      t.timestamps null: false
    end
  end
end
