#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content 
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#
require 'redis'
require 'redis-namespace'
require 'redis-caches/s3_cache'

require 'bloomfilter-rb'
require 'json'
require 'zlib'
require 'socket'

require 'cloud-crawler/logger'


#TODO  move S3 serialization to a seperate module
#  so it can be tested, re-used, and optmized everywhere we use redis
module CloudCrawler
  class RedisPageStore
    include Enumerable


    attr_reader :namespace

    MARSHAL_FIELDS = %w(links visited fetched)
    def initialize(redis, opts = {})
      @redis = redis
      @opts = opts
      @namespace = "#{opts[:job_name]}:pages"
            
      @pages = Redis::Namespace.new(@namespace, :redis => redis)
      @pages.s3_init(opts)   
    end

    def close
      @redis.quit
    end

    # url encode or decode url for keys?
    def key_for(url)
      url.to_s.downcase.gsub("https",'http').gsub(/\s+/,' ')
    end

    # We typically index the hash with a URI,
    # but convert it to a String for easier retrieval
    def [](url)
      rget key_for url
    end

    def []=(url, page)
      rkey = key_for url
      @pages[rkey]= page.to_hash.to_json
    end

    def delete(url)
      page = self[url]
      @pages.del(key_for url)
      page
    end

    def has_page?(url)
      @pages.exists(key_for url)
    end

    def has_key?(key)
      @pages.exists(key)
    end

    def each
      rkeys = @pages.keys("*")
      rkeys.each do |rkey|
        page = rget(rkey)
        url = key_for page.url
        yield url, page
      end
    end

    def merge!(hash)
      hash.each { |key, value| self[key] = value }
      self
    end

    def size
      @pages.keys("*").size
    end

    def keys
      @pages.keys("*")
    end

    # when do we do this?  only on serialization
    def each_value
      each { |k, v| yield v }
    end

    def values
      result = []
      each { |k, v| result << v }
      result
    end


    def save!
      @pages.s3.save!
    end
    
    def save
       @pages.s3.save
    end
    
    def delete!(keys)
      @pages.pipelined do
        keys.each { |k| @pages.del k }
      end
      return keys
    end

    private

    def rget(rkey)
      Page.from_hash(JSON.parse(@pages[rkey]))
    end

  end
end
