require 'cloud-crawler/http'
require 'cloud-crawler/redis_page_store'
require 'cloud-crawler/page'
require 'active_support/inflector'
require 'active_support/core_ext'

module CloudCrawler
  
  
  # idea for a recurring job that could serialize specific keys from a page store
  # not used yet
  class PageStoreJob
   #  include RedisSerializer
  
    # should be part of a job base class redis-serializer or general job class
    def self.init(job)
      @key_prefix = @opts[:key_prefix] || 'cc'
      # connects to remote cache...but could be local cache also
      @cache = Redis::Namespace.new("#{@key_prefix}:cache", :redis => job.client.redis)
      @page_store = RedisPageStore.new(job.client.redis,@opts)  
      @queue = job.client.queues[@opts[:qless_local]]   # or master local
    end
  
    # master cache
    def self.cache
      @cache
    end
   
    # job is scheuled
    #  how?  where?  here or when put on queue?
    def self.perform(job)
      data = job.data.symbolize_keys
      @opts = JSON.parse(data[:opts]).symbolize_keys
      init(job)
             
      # snapshot to delete, maybe even have job id
      # should have base url
      timestamp = Time.now.to_s.gsub(/\s/,'-')
      filename = "#{@page_store.name}.#{timestamp}.jsons"
      #TODO:  use gzip stream
      File.open(filename) do |f|
      urls = []   
      @page_store.each do |url,page|
          urls << url
          f << { url => page.to_json }.to_json << "\n"
        end
      end
      
      
      # TODO:  perform some basic check on filename, like # of lines ? or checksum
      
      # TODO:  push to s3 
      
      # TODO:  pipeline this
      @page_store.delete_pages(urls)
     
      
    end
   
  end

end