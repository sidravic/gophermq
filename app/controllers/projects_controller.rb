class ProjectsController < ApplicationController
  before_filter :require_user

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
end
