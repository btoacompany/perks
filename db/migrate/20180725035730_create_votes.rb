class CreateVotes < ActiveRecord::Migration
  def change
    create_table :votes do |t|
      t.references :company
      t.date :date, null: false
      t.string :title, null: false, default: ""
      t.string :question, null: false
      t.text :header_image_url

      t.timestamps null: false
    end
  end
end
