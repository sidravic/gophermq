class ApplicationController < ActionController::Base
  	protect_from_forgery

  	private

  	def protect_with_http_basic_auth  		
  		authenticate_or_request_with_http_basic do |u, p|
  			project = Project.where(:application_id => u, :private_key => p).last  			
  			return true if project.present?  			
  		end

  		false
  	end

  	def require_user
  		unless current_user.present?
  			flash[:notice] = "Please login to access this section"
  			redirect_to root_url 
  		end	
  	end
end
