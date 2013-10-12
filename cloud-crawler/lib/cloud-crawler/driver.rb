#!/usr/bin/env ruby
#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content (TM)
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
require 'cloud-crawler/dsl_front_end'
require 'cloud-crawler/exceptions'
require 'cloud-crawler/crawl_job'
require 'cloud-crawler/batch_crawl_job'
require 'cloud-crawler/worker'
require 'cloud-crawler/logger'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'json'
require 'sourcify'
require 'qless'

module CloudCrawler
  VERSION = '0.2';
    
  #
  # Convenience methods to start a crawl
  #
    
  def CloudCrawler.crawl(urls, opts = {}, &block)
    opts.reverse_merge! CloudCrawler::Driver::DRIVER_OPTS
    Driver.crawl(urls, opts, &block)
  end
  
    
  def CloudCrawler.standalone_crawl(urls, opts = {}, &block)
    opts.reverse_merge! CloudCrawler::Driver::DRIVER_OPTS
    Driver.crawl(urls, opts, &block)
    Worker.run(opts)
  end
  
  
  def CloudCrawler.batch_crawl(urls, opts = {}, &block)
    opts.reverse_merge! CloudCrawler::Driver::DRIVER_OPTS
    Driver.batch_crawl(urls, opts, &block)
  end
  
  def CloudCrawler.batch_curl(urls, opts = {}, &block)
    opts.reverse_merge! CloudCrawler::Driver::DRIVER_OPTS
    Driver.batch_curl(urls, opts, &block)
  end
  

 
  def CloudCrawler.standalone_batch_crawl(urls, opts = {}, &block)
    opts.reverse_merge! CloudCrawler::Driver::DRIVER_OPTS
    Driver.batch_crawl(urls, opts, &block)
    Worker.run(opts)
  end
  
  def CloudCrawler.standalone_batch_curl(urls, opts = {}, &block)
    opts.reverse_merge! CloudCrawler::Driver::DRIVER_OPTS
    Driver.batch_curl(urls, opts, &block)
    Worker.run(opts)
  end
  
  

  class Driver
    include DslFrontEnd

    # time a batch job has before it times out
    DEFAULT_HEARTBEAT_IN_SEC = 600

    DRIVER_OPTS = {
      :job_name => "cc",
      :queue_name => "crawls",
      :qless_host => 'localhost',
      :qless_port => 6379,
      :qless_db => 0,  # not used yet..not sure how
      # :qless_queue => "cc",
      :verbose => true,
      :interval => 10,
      :job_reserver => 'Ordered'
    
    }

    def initialize(opts = {}, &block)
      opts.reverse_merge! DRIVER_OPTS
      init(opts)
      @client = Qless::Client.new( :host => opts[:qless_host], :port => opts[:qless_port] )
      @queue = @client.queues[opts[:queue_name]]
      @client.config['heartbeat'] = opts[:timeout] || DEFAULT_HEARTBEAT_IN_SEC
      
      # same as client code base
      # perhaps should isolate somewhere
      namespace = opts[:job_name]
      LOGGER.info "initialzing driver for #{namespace}"
      @cc_master_q = Redis::Namespace.new("#{namespace}:ccmq", :redis =>  @client.redis)
      
      yield self if block_given?
    end
    
    def normalize_link(url)
      url = URI(url) unless url.instance_of? URI
      url.path = '/' if url.path.empty?
      return url.to_s
    end
    
      
   def auto_increment?
     @opts[:auto_increment] 
   end
   
   
   def next_batch_id
      @cc_master_q.incr("auto_batch_ids")
   end
   
   def next_job_id
      @cc_master_q.incr("auto_job_ids")
   end
   
    def next_dsl_id
      @cc_master_q.incr("auto_dsl_id")
   end
   
   
    
   # TODO;  eventually consolidate these apis

    def load_crawl_job(hsh) 
      LOGGER.info "loading crawl job = #{hsh}"
      
      data = {}
      data[:opts] = make_opts  
      data[:dsl_id] = make_blocks   
      
      data[:link] = normalize_link( hsh[:url])
      data.reverse_merge!(hsh)
      
      LOGGER.info "keys on ccmq #{@cc_master_q.keys}"
      submit( CrawlJob, data, @opts )
    end
    
    
   def auto_increment(batch)
     return if batch.nil? or batch.empty? 
     job = batch.first
     job[:batch_id] = next_batch_id  if job[:batch_id].nil? 
  
      if job[:job_id].nil? then
        batch.each { |hsh|  hsh[:job_id] = next_job_id }
      end    
      LOGGER.info "auto-increment batch_id = #{job[:batch_id]}"
   end
   
 
    # see DslFrontEnd, sorry
    def put_blocks_in_cache(data)
      # does not work  :   id = json.hash ... really need id from job submitted
      id = next_dsl_id
      @cc_master_q["dsl_blocks:#{id}"]=data  # compressed json
      return id
    end
    
    
    def load_batch_crawl(batch) 
      LOGGER.info "loading batch crawl job #{batch}"
      auto_increment(batch) if auto_increment?
      
      data = {}
      data[:opts] = make_opts 
      data[:dsl_id] = make_blocks
      
      batch.each do |hsh| 
         hsh[:link] = normalize_link( hsh[:url] )
       end
      
      data[:batch] = make_batch batch
      submit( BatchCrawlJob, data, @opts )
    end
    
 
   def load_batch_curl(batch) 
      LOGGER.info "loading batch curl job #{batch}"
      auto_increment(batch) if auto_increment?
     
      data = {}
      data[:opts] = make_opts   
      data[:dsl_id] = make_blocks
       
      batch.each do |hsh| 
         hsh[:link] = normalize_link( hsh[:url] )
       end
      
      data[:batch] = make_batch batch
      submit( BatchCurlJob, data, @opts )   
     
    end
     
    # klass = CrawlJob | BatchCrawlJob | BatchCurlJob
    def submit( klass, data, opts)
       data[:root_job] = true
       if @opts[:recur] then    
        recur_time =  @opts[:recur].to_i
        LOGGER.info "submitting #{klass} job, every #{recur_time} seconds" 
        # add timestamp :  submit_time   
         @queue.recur( klass, data, recur_time )
      else
         LOGGER.info "submitting #{klass} single (non recurring) job"   
          
         @queue.put(klass, data)
      end
    end
      
    
    #
    # Convenience method to start a new crawl
    #
    def self.crawl(urls, opts = {}, &block)
      msg = "crawl #{urls} "
      msg += " with #{block.to_source}"  if block
      LOGGER.info msg

      LOGGER.info "no urls to crawl" if urls.nil? or urls.empty?
      self.new(opts) do |core|
        yield core if block_given?

        jobs = [urls].flatten
        jobs.map!{ |url| { :url => url } }  unless jobs.first.is_a? Hash
        jobs.each do |hsh|
          core.load_crawl_job(hsh) 
        end

      end
    end

    def self.batch_crawl(urls, opts = {}, &block)
      LOGGER.info "no urls to batch crawl" if urls.nil? or urls.empty?
      self.new(opts) do |core|
        yield core if block_given?

        jobs = [urls].flatten
        jobs.map!{ |url| { :url => url } }  unless jobs.first.is_a? Hash
        core.load_batch_crawl(jobs)
      end
    end


   def self.batch_curl(urls, opts = {}, &block)
      LOGGER.info "no urls to batch crawl" if urls.nil? or urls.empty?
      self.new(opts) do |core|
        yield core if block_given?

        jobs = [urls].flatten
        jobs.map!{ |url| { :url => url } }  unless jobs.first.is_a? Hash
        core.load_batch_curl(jobs)
      end
    end
   

  end # Driver

end

#TODO: set first job somehow
# dodo:  set auto-inc keys for re-sbumits
# defauylt:  first jonb = job_id 0 and batch_id 0
#  can reset to 1, 1 with dsl
#  can rest to something else?

