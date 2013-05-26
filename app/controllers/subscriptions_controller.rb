class SubscriptionsController < ApplicationController

	before_filter :get_queue, :except => [:index]
	before_filter :require_user, :only => [:index]

	def index
		@project = current_user.projects.where(:application_id => params[:project_id]).last
		raise ActiveRecord::RecordNotFound, "Project Not Found" if @project.nil?
		@gopher_queue = @project.gopher_queues(:name => params[:queue_name]).last
		raise ActiveRecord::RecordNotFound, "Queue Not Found" if @gopher_queue.nil?

		@subscribers = @gopher_queue.subscribers
	end

	#############################################################################################
	#
	#   Replace project_id with application_id 
	#	POST /projects/:project_id/queues/:queue_name/subscriptions
	# 	{
	# 		:subscribe_to_queue_name => "testmq"
	#  	}
	# 	Creates a subscription. The queue <em>:queue_name</em> subscribes to the queue 
	# 	<em> :subscribe_to_queue_name </em>. After the subscriptions all messages sent to queue
	# 	'testmq' are forwarded to :queue_name
	#############################################################################################
  	def create
  		@subscribe_to_queue = @project.gopher_queues.where(:name => params[:subscribe_to_queue_name]).last  		
  		raise ActiveRecord::RecordNotFound, "Queue Not Found" if @subscribe_to_queue.nil?  		
  		@subscription = Subscription.new(:gopher_queue_id => @gopher_queue.id, :subscriber_id => @subscribe_to_queue.id)

  		if @subscription.save
  			render :json => {:operation_status => true, :subscription => @subscription}, :status => :ok
  		else
  			subscription = Subscription.where(:gopher_queue_id => @gopher_queue.id, :subscriber_id => @subscribe_to_queue.id).last
  			render :json => {:operation_status => false, :errors => @subscription.errors.full_messages.join(". "), :subscription => subscription}, :status => :unprocessable_entity
  		end
  	rescue ActiveRecord::RecordNotFound => e
  		Rails.logger.error("[ERROR] #{e.message} #{e.backtrace}")
  		render :json => {:operation_status => false, :errors => ["Queue Not Found"]}, :status => :not_found    
  	rescue => e
  		Rails.logger.error("[ERROR] #{e.message} #{e.backtrace}")
        render :json => {:operation_status => false, :errors => ["#{e.message}"]}, :status => :internal_server_error    
  	end

  	#############################################################################################
  	#   Replace project_id with application_id 
	#	DELETE /projects/:project_id/queues/:queue_name/subscriptions/:id
	#
	# 	Deletes a subscription identified by the subscription :id. 
	#############################################################################################
  	def destroy
  		@subscription = @gopher_queue.subscriptions.find(params[:id])
  		if @subscription.destroy
  			render :json => {:operation_status => true, :subscription => @subscription}, :status => :ok
  		else
  			render :json => {:operation_status => false, :susbcription => @subscription}, :status => :unprocessable_entity
  		end
  	rescue ActiveRecord::RecordNotFound => e
  		Rails.logger.error("[ERROR] #{e.message} #{e.backtrace}")
  		render :json => {:operation_status => false, :errors => ["Subscription Not Found"]}, :status => :not_found    
  	rescue => e
  		Rails.logger.error("[ERROR] #{e.message} #{e.backtrace}")
        render :json => {:operation_status => false, :errors => ["#{e.message}"]}, :status => :not_found    	
  	end

  	private

  	def get_queue
  		@project = Project.where(:application_id => params[:project_id]).last        
        raise ActiveRecord::RecordNotFound, "Project Not Found" if @project.nil?
        @gopher_queue = @project.gopher_queues.where(:name => params[:queue_name]).last
        raise ActiveRecord::RecordNotFound, "Queue Not Found" if @gopher_queue.nil?
    rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error("[ERROR] #{e.message} #{e.backtrace}")
        render :json => {:operation_status => false, :errors => ["#{e.message}"]}, :status => :not_found
    rescue => e
        Rails.logger.error("[ERROR] #{e.message} #{e.backtrace}")
        render :json => {:operation_status => false, :errors => ["#{e.message}"]}, :status => :not_found    
  	end
end
