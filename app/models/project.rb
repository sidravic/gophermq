class Project < ActiveRecord::Base
  attr_accessible :application_id, :private_key, :user_id, :name

  #validations
  validates :application_id, :presence => true, :uniqueness => true
  validates :private_key, :presence => true, :uniqueness => true
  validates_presence_of :user_id 

  #associations
  belongs_to :user
  has_many :gopher_queues, :dependent => :destroy

  # filters
  before_validation :generate_appid_and_key

  def generate_appid_and_key  	
  	if self.new_record?
  		self.application_id = generate_application_id
  		self.private_key = generate_private_key
  	end
  end

  def generate_application_id
    begin
  	    application_id = "#{SecureRandom.hex(5)}#{Time.now.to_i}"
    end while self.class.exists?(:application_id => application_id)

    application_id
  end  

  def generate_private_key
  	Guid.new.hexdigest.to_s
  end
end


