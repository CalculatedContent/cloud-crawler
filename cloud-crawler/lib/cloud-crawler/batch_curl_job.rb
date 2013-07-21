require 'cloud-crawler/logger'
require 'cloud-crawler/http'
require 'cloud-crawler/batch_job'
require 'cloud-crawler/redis_page_store'
require 'cloud-crawler/redis_url_bloomfilter'
require 'cloud-crawler/dsl_core'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'redis-caches/s3_cache'

# Like a batch crawl job, but does not check the bloomfilter or follow any links
# used to simple retrieve a list of URLs
module CloudCrawler
  class BatchCurlJob < BatchJob
    
    def self.init_with_pagestore(qjob)   
      @page_store = RedisPageStore.new(@local_redis,@opts)
      @http_cache={}
      @http=nil
      init_without_pagestore(qjob)
    end
    
   
    def self.http
       @http
    end
    
    class << self
      alias_method_chain :init, :pagestore
    end
    
    

    def self.process_job(job)
      LOGGER.info "processing curl job #{job}"
      next_jobs = []

      link, referer, depth = job[:link], job[:referer], job[:depth]
      
      return next_jobs if link.nil? or link.empty? or link == :END

      # hack for cookies .. should be jid  is this correct?
      # VERY BAD
      @http_cache[job[:qid]] ||=  CloudCrawler::HTTP.new(@opts)
      @http=@http_cache[job[:qid]]
      
      return next_jobs if http.nil?
      
      fetched_pages = http.fetch_pages(link, referer, depth) # hack for testing

      fetched_pages.flatten!
      fetched_pages.compact!

      fetched_pages.each do |page|
        next if page.nil?
        do_page_blocks(page)  #DSL  should optimize .. can i convert to a singleton method
      end

      fetched_pages.each do |page|
        # TODO:  normalize the url to avoid parameter shuffling
        url = page.url.to_s
        @page_store[url] = page unless @opts[:discard_page]
      end


      return next_jobs
    end

  end

end

#TODO: add timestamp to logging
#  test
