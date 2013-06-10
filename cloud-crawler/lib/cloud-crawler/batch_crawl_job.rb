require 'cloud-crawler/logger'
require 'cloud-crawler/http'
require 'cloud-crawler/batch_job'
require 'cloud-crawler/redis_page_store'
require 'cloud-crawler/redis_url_bloomfilter'
require 'cloud-crawler/dsl_core'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'redis-caches/s3_cache'

module CloudCrawler
  class BatchCrawlJob < BatchJob
    
    def self.init_with_pagestore(qjob)   
      @page_store = RedisPageStore.new(@local_redis,@opts)
      @bloomfilter = RedisUrlBloomfilter.new(@redis)
      init_without_pagestore(qjob)
    end
    
    class << self
      alias_method_chain :init, :pagestore
    end
    
    

    def self.process_job(job_hsh)
      next_jobs = []

      link, referer, depth = job_hsh[:link], job_hsh[:referer], job_hsh[:depth]
      
      return next_jobs if link.nil? or link.empty? or link == :END
      return next_jobs if @bloomfilter.visited_url?(link.to_s)

      http = CloudCrawler::HTTP.new(@opts)
      return next_jobs if http.nil?
      
      fetched_pages = http.fetch_pages(link, referer, depth)

      fetched_pages.flatten!
      fetched_pages.compact!
      fetched_pages.reject! { |page|  @bloomfilter.visited_url?(page.url.to_s) }

      fetched_pages.each do |page|
        next if page.nil?
        do_page_blocks(page)
      end

      fetched_pages.each do |page|
        # TODO:  normalize the url to avoid parameter shuffling
        url = page.url.to_s

        links = links_to_follow(page)
        links.reject! { |lnk| @bloomfilter.visited_url?(lnk) }
        links.each do |lnk|
          # next if lnk.to_s==url  # avoid loop
          next if depth_limit and (page.depth + 1 > depth_limit)
          next_job = { :link => lnk.to_s, :referer => page.referer.to_s, :depth => page.depth + 1}
          next_job.reverse_merge!(job_hsh)
          next_jobs << next_job
        end

        page.discard_doc! if @opts[:discard_page_bodies]
        @page_store[url] = page  # will stil store links, for depth analysis later .. not critical to store
      end

      # must optionally turn off caching for testing

      # hard, synchronous flush  to s3 (or disk) here
      saved_urls = if @flush then  @page_store.save! else @page_store.keys end

      # add pages to bloomfilter only if store to s3 succeeds
      saved_urls.each { |url|  @bloomfilter.visit_url(url) }
      
      next_jobs.flatten!
      next_jobs.compact!

      return next_jobs
    end

  end

end

