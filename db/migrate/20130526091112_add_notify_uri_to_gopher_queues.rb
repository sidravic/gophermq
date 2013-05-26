class AddNotifyUriToGopherQueues < ActiveRecord::Migration
  def change
    add_column :gopher_queues, :notify_uri, :string
  end
end
