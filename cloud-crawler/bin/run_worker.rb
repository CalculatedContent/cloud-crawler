#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'trollop'

require 'socket'
require 'cloud_crawler'
require 'cloud_crawler/worker'


opts = Trollop::options do
  opt :name, "name of crawl", :short => "-n",  :default => "crawl"  # must be same as start
  opt :worker_id, "id for this worker", :short => "-w", :default => Socket.gethostname
  
  opt :qless_host, "", :short => "-h", :default => 'localhost'
  opt :qless_port,"",  :short => "-p", :default => 6379
  opt :qless_db, "", :short => "-B", :default => 0
  
  #opt :qless_queue, "", :short => "-q", :default => "crawl"   # :multi => true 

  opt :interval, "", :short => "-i", :default => 0
  opt :job_reserver, "", :short => "-r", :default => 'Ordered'
  opt :verbose, "", :short => "-v", :default => true
  opt :single_process, "run as single process", :short => "-s", :default => false  
end

CloudCrawler::Worker.run(opts)


