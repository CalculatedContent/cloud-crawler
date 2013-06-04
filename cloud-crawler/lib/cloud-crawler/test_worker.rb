require 'cloud-crawler/exceptions'
require 'qless'


# Only used for basic testing
module CloudCrawler


  class TestWorker
    
     WORKER_OPTS = {     
      :qless_host => 'localhost',
      :qless_port => 6379,
      :qless_queue => "crawls",
      :interval => 10
     }
    
     
    def initialize(opts = {}, &block)
      opts.reverse_merge! WORKER_OPTS
      @opts = opts
      @client = Qless::Client.new( :host => opts[:qless_host], :port => opts[:qless_port])
      @queue = @client.queues[opts[:qless_queue]]
      yield self if block_given?
    end
    
     # Convenience method to start a new crawl
    #
    def self.run(opts={}, &block)
      self.new(opts) do |core|
        yield core if block_given?
        core.run
      end
    end

 
    def run
      while job=@queue.pop
        job.perform
        sleep(@opts[:delay])
      end
    end
    
    
  end
  
end


if __FILE__==$0 then
  opts = Trollop::options do
   opt :qless_host,  :short => "-f", :default => WORKER_OPTS[:qless_host]
   opt :qless_port, :short => "-p", :default => WORKER_OPTS[:qless_port]
   opt :qless_queue, :short => "-q", :default => WORKER_OPTS[:qless_queue]
   opt :interval, :short => "-i", :default => WORKER_OPTS[:interval]
   end
 Worker.run(opts)
end



   


