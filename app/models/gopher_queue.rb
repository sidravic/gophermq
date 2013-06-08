class GopherQueue < ActiveRecord::Base
  attr_accessible :name, :project_id, :queuetype

  #validation
  validates_presence_of :name, :project_id
  validates_uniqueness_of :name, :scope => :project_id
  validate :validate_notify_uri

  #associations
  belongs_to :project
  has_many :jobs
  
  has_many :subscriptions
  has_many :subscribers, :class_name => "GopherQueue", :through => :subscriptions
  

  attr_accessible :notify_uri, :queuetype

  def to_param
  	self.name.to_s
  end

  def validate_notify_uri       
    self.errors.add(:notify_uri, "Invalid notify uri format") if self.notify_uri.blank? && self.queuetype == :notifiable.to_s
  end

  def valid_notify_uri?
    !!URI.parse(self.notify_uri)
  rescue URI::InvalidURIError
    false
  end

  def clear
    message_queue = Datastore::MessageQueue.new(self)
    message_queue.destroy
  end

  def list_jobs    
    message_queue = Datastore::MessageQueue.new(self)
    message_queue.list_redis_jobs
  end

  def subscribed?
    self.queuetype.to_sym == :subscribed
  end

  def notifiable?
    self.queuetype.to_sym == :notifiable
  end

  def notify!
    status = false
    transaction do       
      if self.update_attributes(:queuetype => :notifiable.to_s)
         message_queue = Datastore::MessageQueue.new(self)
         message_queue.notify!(self.notify_uri)
         status = true
       end
    end
    status
  end

  def denotify!
    status = false
    transaction do
      if self.update_attributes(:queuetype => :standard.to_s, :notify_uri => nil)
        message_queue = Datastore::MessageQueue.new(self)
        message_queue.denotify!
        status = true
      end
    end
    status
  end  
end
