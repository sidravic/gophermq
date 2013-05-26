class ApplicationController < ActionController::Base
  protect_from_forgery

  private

  def require_user
  	unless current_user.present?
  		flash[:notice] = "Please login to access this section"
  		redirect_to root_url 
  	end	
  end
end
