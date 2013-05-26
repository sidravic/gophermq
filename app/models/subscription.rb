class Subscription < ActiveRecord::Base
  attr_accessible :gopher_queue_id, :subscriber_id

  validates_uniqueness_of :subscriber_id, :scope => :gopher_queue_id, :message => "Subscription already exists"

  belongs_to :gopher_queue
  belongs_to :subscriber, :class_name => "GopherQueue", :foreign_key => :subscriber_id
end
