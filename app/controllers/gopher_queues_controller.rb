class GopherQueuesController < ApplicationController 
    before_filter :protect_with_http_basic_auth, :only => [:create, :destroy, :notify, :denotify, :subscribe, :unsubscribe] 
    before_filter :require_user, :only => [:index]
    before_filter :require_application, :except => [:new]
    protect_from_forgery :only => :index

    def index
        page = params[:page] || 1
        @project = Project.find(params[:project_id])
        @gopher_queues = @project.gopher_queues.page(page).per(20)
    end

    def new
    end

    def show      
        @project = Project.where(:application_id => params[:project_id]).last
        @gopher_queue = @project.gopher_queues.find(params[:id])  
        render :json => {:status => true, :status_code => "200", :gopher_queue => @gopher_queue}, :status => :ok
    rescue => e
        render :json => {:status => false, :status_code => "422", :errors => "Unprocessable Entity"}, :status => :unprocessable_entity
    end

  #############################################################################################
  # POST /projects/:project_id/queues
  # Replace project_id with application_id
  #  { 
  #    :name => "queue_name",
  #    :application_id => "AXX23334SQXSS233S7Z",   
  #    :job_data => "{id: 1121}" [OPTIONAL]
  #  
  #  }
  #############################################################################################
    def create    
        @gopher_queue = @project.gopher_queues.where(:name => params[:name]).last    

        if @gopher_queue.present?
            @job = @gopher_queue.jobs.create(:data => params[:job_data]) if params[:job_data].present?     
            response_hash = {:operation_status => false, 
                             :queue => @gopher_queue.attributes.except("project_id", "queuetype"),  
                             :application_id => @project.application_id}

            if @job.present? && !@job.new_record?                 
                @job.enqueue
                response_hash.merge!(:job => @job.attributes.except("gopher_queue_id")) 
            end
            render :json => response_hash, :status => :ok    
        else   
            @gopher_queue = @project.gopher_queues.build(:name => params[:name]) 
            @job = @gopher_queue.jobs.build(:data => params[:job_data]) if params[:job_data].present?

            if @gopher_queue.save    
                @job.enqueue
                response_hash = {:operation_status => true,                          
                                 :application_id => @project.application_id, 
                                 :queue => @gopher_queue.attributes.except("project_id", "queuetype")
                                }

                response_hash.merge!(:job => @job.attributes.except("gopher_queue_id")) unless @job.new_record?
                render :json => response_hash, :status => :ok   
            else
                render :json => {:operation_status => false,                          
                                 :errors => @gopher_queue.errors.full_messages.join(". ")}, :status => :ok  
            end    
        end
    rescue => e
        Rails.logger.error("[ERROR] #{e.message} #{e.backtrace}")
        render :json => {:operation_status => false, :errors => ["Something went wrong on our server"]}, :status => :internal_server_error
    end

    def edit
    end

  #############################################################################################
  #  DELETE /projects/:project_id/queues/:id
  #  Replace :project_id with :application_id
  #  Data: {  
  #           //No data expected
  #           // Will delete a queue containing jobs as well  
  #        }
  #
  #############################################################################################
    def destroy
        @gopher_queue = @project.gopher_queues.where(:name => params[:queue_name]).last
        raise ActiveRecord::RecordNotFound, "QueueNotFound" if @gopher_queue.nil?
        if @gopher_queue.destroy            
            @gopher_queue.clear
            response_hash =  {:operation_status => true, 
                              :queue => @gopher_queue.attributes.except("project_id", "queuetype")                              
                              }
            response_hash.merge!(:jobs => @gopher_queue.jobs) if !@gopher_queue.jobs.empty?                              
            render :json => response_hash, :status => :ok                              
        else
            response_hash = {:operation_status => false, :queue => @gopher_queue.attributes.except("project_id", "queuetype")}
            render :json => response_hash, :status => :unprocessable_entity
        end
    rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error("[ERROR] Queue Not Found")
        render :json => {:operation_status => false, :errors => ["Queue Not Found"]}, :status => :not_found
    rescue => e
        Rails.logger.error("[ERROR] #{e.message} #{e.backtrace}")
        render :json => {:operation_status => false, :errors => ["Something went wrong on our server"]}, :status => :internal_server_error
    end
    
    def update
    end

    #############################################################################################
    # PUT /projects/:project_id/queues/:queue_name/notify
    # // Replace project_id with :application_id
    # {
    #   :notify_uri =>   http://example.org/gophermq/notify
    #  }
    #
    # The method makes a queue into a notifiable queue. A notifiable queue POSTs to a callback url 
    # updated everytime a message is added the the queue. It acts like a web hook.
    #
    #############################################################################################
    def notify
        @gopher_queue = @project.gopher_queues.where(:name => params[:queue_name]).last
        raise ActiveRecord::RecordNotFound, "QueueNotFound" if @gopher_queue.nil?

        if @gopher_queue.notifiable?            
            render :json => {:operation_status => false, :errors => ["Queue is already notifiable"], :queue => @gopher_queue.attributes.except("project_id")}, :status => :unprocessable_entity 
        else
            @gopher_queue.notify_uri = params[:notify_uri]
            if @gopher_queue.notify!            
                render :json => {:operation_status => true, :queue => @gopher_queue.attributes.except("project_id")}, :status => :ok
            else                
                render :json => {:operation_status => false, :errors => @gopher_queue.errors.full_messages.join(". "), :queue => @gopher_queue.attributes.except("project_id")}, :status => :unprocessable_entity
            end        
        end
    rescue ActiveRecord::RecordNotFound => e
        Rails.logger.debug("[ERROR] Queue Not Found")
        render :json => {:operation_status => false, :errors => ["Queue Not Found"], :status => :not_found}
    rescue => e
        Rails.logger.debug("[ERROR] #{e.message} #{e.backtrace}")
        render :json => {:operation_status => false, :errors => ["Something went wrong on our servers"]}, :status => :internal_server_error
    end

    #############################################################################################
    # PUT /projects/:project_id/queues/:queue_name/denotify
    # // Replace project_id with :application_id
    # {
    #   :notify_uri =>   http://example.org/gophermq/denotify
    #  }
    #
    # The method makes a queue notifiable queue into a standard queue. A notifiable queue POSTs to a callback url 
    # updated everytime a message is added the the queue. It acts like a web hook.
    #
    #############################################################################################
    def denotify
        @gopher_queue = @project.gopher_queues.where(:name => params[:queue_name]).last
        raise ActiveRecord::RecordNotFound, "QueueNotFound" if @gopher_queue.nil?

        if @gopher_queue.notifiable?
            if @gopher_queue.denotify!
                render :json => {:operation_status => true, :queue => @gopher_queue.attributes.except("project_id")}, :status => :ok
            else
                render :json => {:operation_status => false, :queue => @gopher_queue.attributes.except("project_id")}, :status => :unprocessable_entity
            end
        else
            render :json => {:operation_status => false, :queue => @gopher_queue.attributes.except("project_id")}, :status => :unprocessable_entity
        end
    rescue ActiveRecord::RecordNotFound => e
        Rails.logger.debug("[ERROR] Queue Not Found")
        render :json => {:operation_status => false, :errors => ["Queue Not Found"], :status => :not_found}
    rescue => e
        Rails.logger.debug("[ERROR] #{e.message} #{e.backtrace}")
        render :json => {:operation_status => false, :errors => ["Something went wrong on our servers"]}, :status => :internal_server_error
    end


    #############################################################################################
    # PUT /projects/:project_id/queues/:queue_name/subscribe
    # // Replace project_id with :application_id    
    #
    # This methods updates a queue into a subscribed queue. The queue then becomes available for
    # realtime notifications via websockets
    # 
    #
    #############################################################################################
    def subscribe
        @gopher_queue = @project.gopher_queues.where(:name => params[:queue_name]).last
        raise ActiveRecord::RecordNotFound, "QueueNotFound" if @gopher_queue.nil?

        if !@gopher_queue.subscribed?
            if @gopher_queue.update_attributes(:queuetype => "subscribed")
                render :json => {:operation_status => true, :gopher_queue => @gopher_queue.attributes.except("project_id")}, :status => :ok
            else
                render :json => {:operation_status => false, :gopher_queue => @gopher_queue.attributes.except("project_id"), :errors => @gopher_queue.errors.full_messages.join(". ")}, :status => :unprocessable_entity
            end
        else
            render :json => {:operation_status => false, :gopher_queue => @gopher_queue.attributes.except("project_id")}, :status => :ok
        end
    end

    #############################################################################################
    # PUT /projects/:project_id/queues/:queue_name/unsubscribe
    # // Replace project_id with :application_id    
    #
    # This methods updates a queue into a subscribed queue. The queue then becomes available for
    # realtime notifications via websockets
    # 
    #
    #############################################################################################
    def unsubscribe
        @gopher_queue = @project.gopher_queues.where(:name => params[:queue_name]).last
        raise ActiveRecord::RecordNotFound, "QueueNotFound" if @gopher_queue.nil?

        if @gopher_queue.subscribed?
            if @gopher_queue.update_attributes(:queuetype => "standard")
                render :json => {:operation_status => true, :gopher_queue => @gopher_queue.attributes.except("project_id")}, :status => :ok
            else
                render :json => {:operation_status => false, :gopher_queue => @gopher_queue.attributes.except("project_id"), :errors => @gopher_queue.errors.full_messages.join(". ")}, :status => :unprocessable_entity
            end
        else
            render :json => {:operation_status => false, :gopher_queue => @gopher_queue.attributes.except("project_id")}, :status => :ok
        end
    end


    def require_application
        @project = Project.where(:application_id => params[:project_id]).last    
    end
end
