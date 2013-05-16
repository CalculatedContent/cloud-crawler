require 'cloud-crawler/http'
require 'cloud-crawler/redis_page_store'
require 'cloud-crawler/redis_url_bloomfilter'
require 'cloud-crawler/dsl_core'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'redis-caches/s3_cache'

module CloudCrawler
  class BatchCrawlJob
    include DslCore

    MAX_SLICE_DEFAULT = 1000
    def self.init(job)
      @namespace = @opts[:name]
      @queue_name = @opts[:name]

      @m_cache = Redis::Namespace.new("#{@namespace}:m_cache", :redis =>  job.client.redis)
      @m_cache.s3_init(@opts)

      local_redis = Redis.new(:host=>'localhost')
      @w_cache = Redis::Namespace.new("#{@namespace}:w_cache", :redis =>  local_redis)
      @s3_cache = Redis::Namespace.new("#{@namespace}:s3_cache", :redis =>  local_redis)
      @s3_cache.s3_init(@opts)

      @page_store = RedisPageStore.new(local_redis,@opts)

      @bloomfilter = RedisUrlBloomfilter.new(job.client.redis,@opts)
      @queue = job.client.queues[@queue_name]
      @max_slice = @opts[:max_slice] || MAX_SLICE_DEFAULT
      @flush =  @opts[:flush]
      @depth_limit = @opts[:depth_limit]
    end
    
  
    def self.m_cache
      @m_cache
    end

    def self.w_cache
      @w_cache
    end

    # write only cache
    def self.s3_cache
      @s3_cache
    end
   

    def self.perform(job)
      super(job)
      init(job)

      data = job.data.symbolize_keys
      urls = JSON.parse(data[:urls])
      
      # TODO:  support conintuous crawl
      #  while urls.not_empty?
      #  instead of urls.map, we urls.slice and map each slice
      
      pages = urls.map do |url_data|
        url_data.symbolize_keys!
        link, referer, depth = url_data[:link], url_data[:referer], url_data[:depth]
        next if link.nil? or link.empty? or link == :END
        next if @bloomfilter.visited_url?(link.to_s)
  
    #    $stderr << "crawling #{link.to_s}  \n"
         
        if delay then
        #  $stderr << "sleeping for #{delay} secs \n"
          sleep(delay)      
        end
        
        http = CloudCrawler::HTTP.new(@opts)
        next if http.nil?
        fetched_pages = http.fetch_pages(link, referer, depth)
        
        fetched_pages.flatten!
        fetched_pages.compact!
        fetched_pages.reject! { |page|  @bloomfilter.visited_url?(page.url.to_s) }
      
        fetched_pages.each do |page|
           next if page.nil?
           do_page_blocks(page) 
        end
        
        fetched_pages
      end

      return if pages.nil? or pages.empty?

      pages.flatten!
      pages.compact!
      return if pages.empty?

      outbound_urls = []

      #  only master cache is/can be/should be pipelined to reduce network traffic
      #  local cache is slow anyway
      
      # worry about this later
      
      #  s3_cache.pipelined do
      
      
        pages.each do |page|
         

          # cache page locally, we assume
          #  or @page_store << page
          url = page.url.to_s
          
          #  TODO:  possibly remove parameters to ignore ... option on DSL
            # TODO:  normalize the url to avoid parameter shuffling


          links = links_to_follow(page)
          links.reject! { |lnk| @bloomfilter.visited_url?(lnk) }
          links.each do |lnk|
          # next if lnk.to_s==url  # avoid loop
            next if @depth_limit and page.depth + 1 > @depth_limit
            outbound_urls <<{ :link => lnk.to_s, :referer => page.referer.to_s, :depth => page.depth + 1}
          end

          page.discard_doc! if @opts[:discard_page_bodies]
          @page_store[url] = page  # will stil store links, for depth analysis later .. not critical to store
        end

     # end

      # must optionally turn off caching for testing

      # hard, synchronous flush  to s3 (or disk) here
      saved_urls = if @flush then  @page_store.save! else @page_store.keys end

      # add pages to bloomfilter only if store to s3 succeeds
      saved_urls.each { |url|  @bloomfilter.visit_url(url) }

      #TODO:  change to allow submit
      outbound_urls.flatten.compact.each_slice(@max_slice) do |urls|
        data[:urls] = urls.to_json
        @queue.put(BatchCrawlJob, data)
      end

      @s3_cache.s3.save!
      
      #  urls <<  outbound_urls.flatten.compact
      # end while not urls.empty?

    end
  end

end



