module Datastore
	class Pubsub
		attr_reader :redis

		def initialize
			@redis =  Datastore::Connection.new.redis
		end

		def publish(channel, message)
			self.redis.publish(channel, message)
		end
	end
end