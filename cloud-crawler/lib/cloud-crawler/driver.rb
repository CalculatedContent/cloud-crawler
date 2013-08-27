#!/usr/bin/env ruby
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
  VERSION = '0.1';
    
  #
  # Convenience methods to start a crawl
  #
  
  
  def CloudCrawler.crawl(urls, opts = {}, &block)
    opts.reverse_merge! CloudCrawler::Driver::DRIVER_OPTS
    Driver.crawl(urls, opts, &block)
  end
  
  def CloudCrawler.batch_crawl(urls, opts = {}, &block)
    opts.reverse_merge! CloudCrawler::Driver::DRIVER_OPTS
    Driver.batch_crawl(urls, opts, &block)
  end
  
  def CloudCrawler.batch_curl(urls, opts = {}, &block)
    opts.reverse_merge! CloudCrawler::Driver::DRIVER_OPTS
    Driver.batch_curl(urls, opts, &block)
  end
  
  
  def CloudCrawler.standalone_crawl(urls, opts = {}, &block)
    opts.reverse_merge! CloudCrawler::Driver::DRIVER_OPTS
    Driver.crawl(urls, opts, &block)
    Worker.run(opts)
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

      yield self if block_given?
    end
    
    def normalize_link(url)
      url = URI(url) unless url.instance_of? URI
      url.path = '/' if url.path.empty?
      return url.to_s
    end
    
   # TODO;  eventually consolidate these apis

    def load_crawl_job(hsh) 
      data = block_sources
      data[:opts] = @opts.to_json
      
      data[:link] = normalize_link( hsh[:url])
      data.reverse_merge!(hsh)
      
      submit( CrawlJob, data, @opts )
    end
    
    def load_batch_crawl(batch) 
      data = block_sources
      data[:opts] = @opts.to_json
       
      batch.each do |hsh| 
         hsh[:link] = normalize_link( hsh[:url] )
       end
      
      data[:batch] = batch.to_json
      submit( BatchCrawlJob, data, @opts )
    end
    
    
   def load_batch_curl(batch) 
      LOGGER.info "loading batch curl job #{batch}"
      data = block_sources
      data[:opts] = @opts.to_json
       
      batch.each do |hsh| 
         hsh[:link] = normalize_link( hsh[:url] )
       end
      
      data[:batch] = batch.to_json
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
          
         @queue.put(klass, data )
      end
    end
      
    #
    # Convenience method to start a new crawl
    #
    def self.crawl(urls, opts = {}, &block)
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
