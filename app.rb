#!/usr/bin/env ruby
# coding: utf-8
require 'bundler/setup'
require 'yaml'
require 'logger'
require 'redis'
require 'eventmachine'

VERBOSE = true

rtarget_cfg = <<-"EOL"
- localhost:10001
- localhost:10002
- localhost:10003
EOL

# rtarget = YAML.load(rtarget_cfg)
rtarget = YAML.load(DATA.read)

## initial
def sybolize_list(hash)
  Hash[hash.map { |k,v| [k.to_sym, v ] }]
end

@logger = Logger.new(STDOUT)
mg_redis = Redis.new
begin
  mg_redis_info = sybolize_list(mg_redis.info)
  @logger.info "ManageNode Conencted: #{mg_redis_info[:redis_version]}"
rescue => e
  @logger.fatal "#{e.class}: #{e.message} #{__LINE__}"
end

@logger.info "start cluster initialize" if VERBOSE
mg_redis.del "cl_lists"
mg_redis.del "cl_stats"
# store tagets to redis
rtarget.each do |rt|
  mg_redis.sadd "cl_lists", rt
  @logger.info "add cluster #{rt}"
end
@logger.info "finished cluster initialize" if VERBOSE

## stats
def update_stats(mg_redis,cl)
  h,p = cl.split(":")
  cr = Redis.new(:host => h, :port => p, :timeout => 0.5)

  begin
    cr_info = sybolize_list(cr.info)
    mg_redis.hset "cl_stats", cl, cr_info[:role]
    if cr_info[:role] == "slave"
      @logger.info "Now node #{cl} status #{cr_info[:role]}. Slave of #{cr_info[:master_host]}:#{cr_info[:master_port]}"
    else
      @logger.info "Now node #{cl} status #{cr_info[:role]}."
    end    
    cr_info[:role]
  rescue Redis::CannotConnectError => e
    mg_redis.hset "cl_stats", cl, "DEAD"
    @logger.warn "Now node #{cl} status DEAD."  
    "DEAD"
  rescue => e
    @logger.fatal "#{e.class}: #{e.message} #{__LINE__}"
    mg_redis.hset "cl_stats", cl, "DEAD"
    @logger.warn "Now node #{cl} status DEAD."
    "DEAD"
  end  

end


# start EM
@logger.info " -- EventMachne: start" if VERBOSE
EM.run do
#   up = proc do
#     mg_redis.smembers("cl_lists").each do |x|
#       begin
#         stat = update_stats(mg_redis, x)
#         mg_redis.hset "cl_stats", x, stat
#       rescue => e
#         @logger.fatal "#{e.class}: #{e.message}"
#       end
#     end
#     @logger.info EM.threadpool_size
#     @logger.info EM.next_tick_queue
#     return "cl_stats", x, stat
#   end
#   callback = proc do |stat|
#     @logger.warn "#{stat}"
#   end

  EM.add_periodic_timer(1) do
    mg_redis.smembers("cl_lists").each do |x|
      begin
        stat = update_stats(mg_redis, x)
        mg_redis.hset "cl_stats", x, stat
      rescue => e
        @logger.fatal "#{e.class}: #{e.message}"
      end
    end
  end

  Signal.trap("SIGINT") do
    @logger.info " -- EventMachne: stop" if VERBOSE
    EM.stop
  end

end


# save
  mg_redis.save

__END__
---
- localhost:10001
- localhost:10002
- localhost:10003
