#!/usr/bin/env ruby
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
  
  

  class Driver
    include DslFrontEnd

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

      yield self if block_given?
    end
    
     def create_job_data(hsh)
      url = hsh[:url]
      url= URI::encode("#{surl}=#{line}") unless url.is_a? URI
      url.path = '/' if url.path.empty?

      data = block_sources
      data[:opts] = @opts.to_json
      data[:link] = url.to_s
      data.reverse_merge!(hsh)
      return data
    end

    def load_crawl_job(hsh) 
       @queue.put( CrawlJob, create_job_data(hsh) )
    end
    
    def load_batch_crawl_job(hsh) 
       @queue.put( BatchCrawlJob, create_job_data(hsh) )
    end
     
      
    #
    # Convenience method to start a new crawl
    #
    def self.crawl(urls, opts = {}, &block)
      logger.info "no urls to crawl" if urls.nil? or urls.empty?
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
      logger.info "no urls to batch crawl" if urls.nil? or urls.empty?
      self.new(opts) do |core|
        yield core if block_given?

        jobs = [urls].flatten
        jobs.map!{ |url| { :url => url } }  unless jobs.first.is_a? Hash
        jobs.each do |hsh|
           core.load_batch_crawl_job(hsh)
        end
      end
    end

   

  end # Driver

end
