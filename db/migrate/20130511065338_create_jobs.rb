class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.integer :gopher_queue_id
      t.text :data
      t.timestamps
    end
  end
end
