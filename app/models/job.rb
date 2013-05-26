class Job < ActiveRecord::Base
  attr_accessible :data

  # validations
  validates_presence_of :data

  #associations
  belongs_to :gopher_queue

  def enqueue
  	message = Datastore::Message.new(self)
  	message.enqueue
  end

  def clear
  	message = Datastore::Message.new(self)
  	message.destroy
  end
end
