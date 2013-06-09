class JobsController < ApplicationController
    before_filter :protect_with_http_basic_auth, :only => [:create, :fetch, :destroy]
    before_filter :get_queue, :except => :index

    def index        
  	    per_page = params[:per_page] || 1  	   
        @project = Project.where(:application_id => params[:application_id]).last
        @gopher_queue = @project.gopher_queues.where(:name => params[:queue_name]).last
  	    @jobs = @gopher_queue.jobs.page(per_page)
    end

    #############################################################################################
    # GET /queues/:queue_name/jobs/list
    #  {
    #    :data => "QueueJobData"
    #    :application_id => "1X2ZASDME2O9K2"
    #  }
    #
    #############################################################################################

    def list
         @jobs = @gopher_queue.list_jobs
         render :json => {:operation_status => true, :jobs => @jobs, :job_count => @jobs.size.to_i, :queue => @gopher_queue.attributes.except("project_id", "id", "queuetype")}, :status => :ok
    rescue => e
        Rails.logger.error("[ERROR] #{e.message} #{e.backtrace}")
        render :json => {:operation_status => false, :errors => ["Something went wrong. Please try again in some time."]}, :status => :internal_server_error 
    end

    #############################################################################################
    # POST /queues/:queue_name/jobs
    #  {
    #    :data => "QueueJobData"
    #    :application_id => "1X2ZASDME2O9K2"
    #  }
    #
    #############################################################################################

    def create  	      	    
  	    @job = @gopher_queue.jobs.build(:data => params[:data])
  	    if @job.save
            @job.enqueue
            @gopher_queue.notify! if @gopher_queue.notifiable?
  		    render :json => {:operation_status => true, :job => @job, :queue => @gopher_queue.attributes.except("project_id")},	:status => :ok
  	    else
  		    render :json => {:operation_status => false, :errors => @job.errors.full_messages.join(". ")}, 
  	 					     :status => :unprocessable_entity
  	    end
    rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error("[ERROR] #{e.message} #{e.backtrace}")
        render :json => {:operation_status => false, :errors => ["QueueNotFound"]}, :status => :not_found
    rescue => e
        Rails.logger.error("[ERROR] #{e.message} #{e.backtrace}")
        render :json => {:operation_status => false, :errors => ["Something went wrong. Please try again in some time."]}, :status => :internal_server_error
    end

    #############################################################################################
    # Return a job from the queue for a given project. Does NOT remove the job from the 
    # job queue. 
    # 
    # GET "/queues/:queue_name/jobs/:id/fetch_name"
    # {
    #   :application_id => "1X2ZASDME2O9K2"
    # } 
    # 
    #
    #############################################################################################

    def fetch
        @job = @gopher_queue.jobs.find(params[:id])
        render :json => {:operation_status => true, :job => @job.attributes.except("gopher_queue_id")}, :status => :ok
    rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error("{ERROR} #{e.message} #{e.backtrace}")
        render :json => {:operation_status => false, :errors => ["Job Not Found"]}, :status => :not_found
    rescue => e
        Rails.logger.error("[ERROR] #{e.message} #{e.backtrace}")
        render :json => {:operation_status => false, :errors => ["Something went wrong. Please try again in some time."]}, :status => :internal_server_error
    end

    #############################################################################################
    # Return a job from the queue for a given project. Deletes the job from the job queue. 
    # A second request will not return a value
    # 
    # DELETE "/queues/:queue_name/jobs/:id"
    # {
    #   :application_id => "1X2ZASDME2O9K2"
    # } 
    # 
    #
    #############################################################################################

    def destroy
        @job = @gopher_queue.jobs.find(params[:id])
        if @job.destroy
            @job.clear
            render :json => {:operation_status => true, :job => @job.attributes.except("gopher_queue_id")}, :status => :ok
        else
            render :json => {:operation_status => false, :job => @job}, :status => :precondition_failed
        end
    rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error("{ERROR} #{e.message} #{e.backtrace}")
        render :json => {:operation_status => false, :errors => ["Job Not Found"]}, :status => :not_found
    rescue => e
        Rails.logger.error("[ERROR] #{e.message} #{e.backtrace}")
        render :json => {:operation_status => false, :errors => ["Internal Server Error."]}, :status => :internal_server_error
    end

    private

    def get_queue
        @project = Project.where(:application_id => params[:application_id]).last        
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
