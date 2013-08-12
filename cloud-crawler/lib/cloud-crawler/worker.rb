#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content 
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#
require 'qless'
require 'qless/worker'

module CloudCrawler
  class Worker
    
    def self.run(opts={})      
      
      ENV['REDIS_URL']= "redis://#{opts[:qless_host]}:#{opts[:qless_port]}/#{opts[:qless_db]}"
      ENV['QUEUES'] = opts[:queue_name]
      
      ENV['JOB_RESERVER'] = opts[:job_reserver]
      ENV['INTERVAL'] = opts[:interval].to_s
      ENV['VERBOSE'] = opts[:verbose].to_s
      ENV['RUN_AS_SINGLE_PROCESS'] = opts[:single_process].to_s

      Qless::Worker::start
    end
    
  end  
end


