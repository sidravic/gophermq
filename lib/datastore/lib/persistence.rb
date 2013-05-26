module Datastore
	module Persistence
		attr_reader :redis, :operation_status

		def initialize_datastore_connection			
			@redis = Datastore::Connection.new.redis
		end		

		def push(key, value)
			@operation_status = redis.lpush(key, value)
		end

		def pop(key)
			@operation_status = redis.rpop(key)
		end

		def peek(key)
			@operation_status = 1
			redis.lindex(key, -1)
		end

		def del(key)			
			@operation_status = redis.del(key)			
		end

		def list(key)						
			@operation_status = 1
			redis.lrange(key, 0, -1)
		end

		def success?
			return true if self.operation_status.nil? && self.operation_status == 1
			false
		end
	end
end