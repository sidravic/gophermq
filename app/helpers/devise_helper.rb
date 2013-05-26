module DeviseHelper
	def devise_error_messages!
		html = ""
		if resource.errors.any?
			html << "<div class='alert alert-error'>"			
			html << "<ul>"
			resource.errors.full_messages.each do |msg|
				html << "<li>"
				html << "#{msg} "
				html << "</li>"
			end
			html << "</div>"			
		end
		raw(html)
	end
end