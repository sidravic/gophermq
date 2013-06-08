module Datastore
	class Key
		def self.generate(queue)
			project = queue.project
			"gophermq:#{project.application_id}_#{queue.name}"
		end

		def self.generate_subscription_key(queue)
			project = queue.project
			"gophermq_subscription_#{project.application_id}_#{queue.name}"
		end
	end


end