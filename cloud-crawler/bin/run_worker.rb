#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'trollop'

require 'socket'
require 'cloud-crawler'
require 'cloud-crawler/worker'


opts = Trollop::options do
  opt :queue_name, "name of crawl", :short => "-q",  :default => "crawls"  # must be same as start
  opt :worker_id, "id for this worker", :short => "-w", :default => Socket.gethostname
  
  opt :qless_host, "qless host", :short => "-h", :default => 'localhost'
  opt :qless_port, "qless port",  :short => "-p", :default => 6379
  opt :qless_db, "qless db", :short => "-B", :default => 0
  
  #opt :qless_queue, "", :short => "-q", :default => "crawl"   # :multi => true 

  opt :interval, "time delay interval", :short => "-i", :default => 0
  opt :job_reserver, "Ordered or RoundRobin", :short => "-r", :default => 'Ordered'
  opt :verbose, "verbos", :short => "-v", :default => true
  opt :single_process, "run as single process", :short => "-s", :default => false  
end

CloudCrawler::Worker.run(opts)


