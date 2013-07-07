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
      return next_jobs if @bloomfilter.visited_url?(link.to_s)

      # hack for cookies 
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

        page.discard_doc! if @opts[:discard_page_bodies]
        @page_store[url] = page @opts[:discard_page]
      end

      # must optionally turn off caching for testing

      # hard, synchronous flush  to s3 (or disk) here
      saved_urls = if save_batch?  then  @page_store.save! else @page_store.keys end

      return next_jobs
    end

  end

end

#TODO: add timestamp to logging
#  test
