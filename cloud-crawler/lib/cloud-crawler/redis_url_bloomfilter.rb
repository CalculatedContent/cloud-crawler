require 'redis'
require 'redis-namespace'
require 'bloomfilter-rb'
require 'json'
require 'zlib'
require 'logger'

    
module CloudCrawler
   
  class RedisUrlBloomfilter
    include Enumerable
    
    attr_reader :namespace
    
    def initialize(redis, opts = {})
      @redis = redis
      @namespace = opts[:job_name] || 'cc'
 
      items, bits = 100_000, 5
      opts[:size] ||= items*bits
      opts[:hashes] ||= 7
      opts[:namespace] = "#{name}"
      opts[:db] = redis
      opts[:seed] = 1364249661
      
      # 2.5 mb? 
     @bloomfilter = BloomFilter::Redis.new(opts)
    end

    # really a bloom filter for anything with sugar
    def name
      "#{@namespace}:bf"
    end

    # same as page store
    def key_for(url)
      url.to_s.downcase.gsub("https",'http').gsub(/\s+/,' ')
    end
    
    
    # bloom filter methods
   
    def insert(url)
     @bloomfilter.insert(key_for url)
    end
    alias_method :visit_url, :insert
    alias_method :touch_url, :insert


    def touch_urls(urls)
      urls.each { |u| touch_url(u) }
    end
    alias_method :visit_urls, :touch_urls 


    def include?(url)
      @bloomfilter.include?(key_for url)
    end
    alias_method :visited_url?, :include?
    alias_method :touched_url?, :include? 


  end
end
