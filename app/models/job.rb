class Job < ActiveRecord::Base
  attr_accessible :data

  # validations
  validates_presence_of :data

  #associations
  belongs_to :gopher_queue

  def enqueue
  	message = Datastore::Message.new(self)
  	message.enqueue
    message.send_subscription_notification if self.gopher_queue.subscribed?
  end

  def clear
  	message = Datastore::Message.new(self)
  	message.destroy
  end
end
