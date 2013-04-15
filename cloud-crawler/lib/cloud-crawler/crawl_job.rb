require 'cloud-crawler/http'
require 'cloud-crawler/redis_page_store'
require 'cloud-crawler/redis_url_bloomfilter'
require 'cloud-crawler/dsl_core'
require 'active_support/inflector'
require 'active_support/core_ext'

module CloudCrawler
  
  class CrawlJob
    include DslCore
  
    def self.init(job)
      @namespace = @opts[:name] || 'cc'
      @queue_name = @opts[:name] || @opts[:qless_queue]
      @cache = Redis::Namespace.new("#{@namespace}:cache", :redis => job.client.redis)
      @page_store = RedisPageStore.new(job.client.redis,@opts)
      @bloomfilter = RedisUrlBloomfilter.new(job.client.redis,@opts)
      @queue = job.client.queues[@queue_name]   
      @depth_limit = @opts[:depth_limit]
    end
  
    def self.cache
      @cache
    end
  
    def self.perform(job)
      super(job)
      init(job)
             
      data = job.data.symbolize_keys
      link, referer, depth = data[:link], data[:referer], data[:depth]     
      return if link == :END     
      

      http = CloudCrawler::HTTP.new(@opts)
      pages = http.fetch_pages(link, referer, depth)
      pages.each do |page|
         url = page.url.to_s
         next if @bloomfilter.visited_url?(url)

         do_page_blocks(page)
         page.discard_doc! if @opts[:discard_page_bodies]
         @page_store[url] = page
         @bloomfilter.visit_url(url)

         links = links_to_follow(page)
         links.each do |lnk|
            next if @bloomfilter.visited_url?(lnk)  
            data[:link], data[:referer], data[:depth] =  lnk.to_s,  page.referer.to_s,  page.depth + 1 
            next if @depth_limit and data[:depth] > @depth_limit 
            @queue.put(CrawlJob, data)
         end
        
     end  
    end
   
  end

end