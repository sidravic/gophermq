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
			binding.pry
			push(key, self.job.data)
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