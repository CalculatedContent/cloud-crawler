#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content (TN)
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#
# All rights reserved.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL MADE BY MADE LTD BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
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



   


