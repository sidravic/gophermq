module Datastore
	class Message
		include Datastore::Persistence

		attr_accessor :job

		def initialize(job)
			@job = job
			initialize_datastore_connection
		end

		def enqueue
			key = Datastore::Key.generate(self.job.gopher_queue)			
			push(key, self.job.data)
		end

		def send_subscription_notification			
			key    = Datastore::Key.generate_subscription_key(self.job.gopher_queue)
			pubsub = Datastore::Pubsub.new
			msg    = {:job => self.job.data}.to_json
			pubsub.publish(key, msg)			
		end

		def get
			key = Datastore::Key.generate(self.job.gopher_queue)
			pop(key)
		end

		def fetch
			key = Datastore::Key.generate(self.job.gopher_queue)
			peek(key)
		end

		def destroy
			key = Datastore::Key.generate(self.job.gopher_queue)
			del(key)
		end
	end
end