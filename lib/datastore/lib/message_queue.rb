module Datastore
	class MessageQueue
		include Persistence

		attr_accessor :gopher_queue

		def initialize(queue)
			@gopher_queue = queue
			initialize_datastore_connection
		end

		def list_redis_jobs			
			key = Datastore::Key.generate(self.gopher_queue)
			list(key)
		end

		def notify!(notify_uri)
			key 	= Datastore::Key.generate(self.gopher_queue)
			message = {:notify_uri => notify_uri, :key => key}.to_json
			pubsub 	= Datastore::Pubsub.new
			pubsub.publish("gophermq_notifiable_notification", message)
		end

		def subscribe!
			key = Datastore::Key.generate(self.gopher_queue)
			pubsub = Datastore::Pubsub.new
			pubsub.publish("gophermq_subscribeable_notification", "#{key}")
		end

		def unsubscribe!
			key = Datastore::Key.generate(self.gopher_queue)
			pubsub = Datastore::Pubsub.new
			pubsub.publish("gophermq_unsubscribe_notification", "#{key}")
		end

		def denotify!
			key = Datastore::Key.generate(self.gopher_queue)
			pubsub = Datastore::Pubsub.new
			pubsub.publish("gophermq_denotify_notification", "#{key}")
		end

		def destroy
			key = Datastore::Key.generate(self.gopher_queue)
			del(key)
		end
	end
end
