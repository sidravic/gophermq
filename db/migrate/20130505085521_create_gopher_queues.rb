class CreateGopherQueues < ActiveRecord::Migration
  def change
    create_table :gopher_queues do |t|
      t.integer :project_id
      t.string :name
      t.string :queuetype, :default => "standard"

      t.timestamps
    end

    add_index :gopher_queues, :project_id
  end
end
