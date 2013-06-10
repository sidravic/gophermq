class ProjectsController < ApplicationController
  before_filter :require_user, :except => [:authenticate]

  def new
  	@project = current_user.projects.build
  end

  def index
  	@projects = current_user.projects
  end

  def create
  	@project = current_user.projects.build(params[:project])

  	if @project.save
  		flash[:notice] = "Project created successfully."
  		redirect_to user_projects_url(current_user)
  	else
  		flash[:error] = @project.errors.full_messages.join(". ")
  		render :new
  	end
  end

  def destroy
  	@project = current_user.projects.find(params[:id])
  	if @project.destroy
  		flash[:notice] = "Project has been successfully created."
  		redirect_to user_projects_url(current_user)
  	else
  		flash[:error] = "Project could deleted."
  		redirect_to user_projects_url(current_user)
  	end
  end

  def authenticate            
      uri             = URI.parse("http://gophermq.com" + params[:url])
      path_attributes = uri.path.split("/")
      application_id  = path_attributes[2]
      queue_name      = path_attributes[4]
      signature       = nil      

      signature_string = "application_id=#{application_id}&queue_name=#{queue_name}&timestamp=" 
      uri.query.split("&").each do |key_value|
          key, value = key_value.split("=")
          signature_string += value.to_s if key.strip == "timestamp"  
          signature = value.to_s if key.strip == "signature"        
      end
      
      project = Project.where(:application_id => application_id).first
      return_unauthorized if project.nil?
      
      private_key = project.private_key
      generated_signature = OpenSSL::HMAC.hexdigest("sha256", signature_string, private_key).chomp

      if generated_signature.strip == signature.strip
        render :json => "ok", :status => 200
      else
        return_unauthorized
      end
  rescue => e  
      return_unauthorized
  end

  private
  def return_unauthorized
    render :json => "Unauthorized", :status => :unauthorized
  end
end
