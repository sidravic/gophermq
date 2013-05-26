class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.integer :user_id
      t.string :application_id
      t.string :private_key
      t.string :name

      t.timestamps
    end

    add_index :projects, :user_id
    add_index :projects, :application_id
  end
end
