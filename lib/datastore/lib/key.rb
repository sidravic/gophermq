module Datastore
	class Key
		def self.generate(queue)
			project = queue.project
			"gophermq:#{project.application_id}_#{queue.name}"
		end
	end


end