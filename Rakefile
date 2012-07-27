# coding: utf-8
require 'bundler/setup'
require 'yaml'
require 'redis'

# shared settings 
redis_ports = %w{10001 10002 10003}
c_dir = File.join(File.dirname(__FILE__))

rtarget_cfg = <<-"EOL"
- localhost:10001
- localhost:10002
- localhost:10003
EOL

rtarget = YAML.load(rtarget_cfg)


desc "spawn three redises"
task "rstart" do
  redis_ports.each do |w|
    rconf = <<-"EOL"
    port #{w}
    pidfile #{c_dir}/tmp/pids/#{w}.pid
    dir #{c_dir}/db/#{w}
    daemonize yes
    EOL
    `mkdir -p ./db/#{w}`
    # puts rconf
    system("echo '#{rconf}' | redis-server -")
  end  
end

desc "stop three redises"
task "rstop" do
  redis_ports.each do |w|
    system("kill `cat #{c_dir}/tmp/pids/#{w}.pid`")
  end  
end

desc "stop three redises"
task "rstopr" do
  system("kill `cat #{c_dir}/tmp/pids/#{redis_ports.shuffle[0]}.pid`")
end

desc "rundom master"
task "rmas" do
  master = rtarget.shuffle[0]
  mh,mp = master.split(":")

  redis_ports.each_with_index do |x,y|
    h,p = rtarget[y].split(":")
    r = Redis.new(:host => h, :port => p)
    begin
      if rtarget[y] == master
        puts "#{rtarget[y]} to master"
        r.slaveof("no","one")
      else
        r.slaveof(mh,mp)
      end
    rescue Redis::CannotConnectError => e
      puts e.message
    end
  end  
end

desc "send ping to all redis"
task "ping" do
  redis_ports.each do |w|
    system("redis-cli -h localhost -p #{w} ping")
  end  
end

desc "send ping to all redis"
task "rping" do
  rtarget_cfg
  redis_ports.each_with_index do |x,y|
    h,p = rtarget[y].split(":")

    r = Redis.new(:host => h, :port => p)
    begin
      puts "#{rtarget[y]} #{r.ping}"
    rescue Redis::CannotConnectError => e
      puts e.message
    end
  end  
end

desc "all master"
task "rmasall" do
  redis_ports.each_with_index do |x,y|
    h,p = rtarget[y].split(":")

    r = Redis.new(:host => h, :port => p)
    begin
      puts "#{rtarget[y]} #{r.slaveof("no","one")}"
    rescue Redis::CannotConnectError => e
      puts e.message
    end
  end  
end




__END__
