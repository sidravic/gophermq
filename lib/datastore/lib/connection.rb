module Datastore
	class Connection
		attr_reader :redis

		def initialize
			@redis = $redis
		end		
	end
end