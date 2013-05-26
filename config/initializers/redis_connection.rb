redis_config = YAML.load_file(Rails.root.join('config', 'redis.yml'))[Rails.env]

if defined?(PhusionPassenger)
	PhusionPassenger.on_event(:start_worker_process) do |forked|
		require "redis"
		$redis.client.disconnect if $redis.present? && $redis.client.present?
		$redis = Redis.new(:host => redis_config['host'], :port => redis_config['port'])
	end
else	
	$redis = Redis.new(:host => redis_config['host'], :port => redis_config['port'])
end