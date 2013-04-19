require 'redis'
require 'redis-namespace'
require 'bloomfilter-rb'
require 'json'
require 'zlib'
require 'socket'

#TODO  move S3 serialization to a seperate module
#  so it can be tested, re-used, and optmized everywhere we use redis
module CloudCrawler
  class RedisPageStore
    include Enumerable


    attr_reader :namespace, :save_to_s3, :save_to_dir, :worker_id, :s3bucket, :s3folder

    MARSHAL_FIELDS = %w(links visited fetched)
    def initialize(redis, opts = {})
      @redis = redis
      @opts = opts
      @namespace = "#{opts[:name]}:pages"
      
      @pages = Redis::Namespace.new(@namespace, :redis => redis)
      @save_to_s3 =  opts[:save_to_s3]  
      @save_to_dir =  opts[:save_to_dir]  

      @worker_id = opts[:worker_id] || Socket.gethostname
      @s3bucket = @save_to_s3
      @s3folder = opts[:name]
      @s3name = @namespace.gsub(/:/,"-")      
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

    # # very dangerous if all redis are saved
    # # at least can we place in a seperate db?
    #  wait for this

    # def flush!
    # @redis.save
    # @redis.flushdb
    # end
    #
    # def save
    # @redis.save
    # end

    # # simple implementation for testing locally
    # def old_flush!
      # keys, filename = save_keys
      # push_to_s3!(filename) if @save_to_s3
      # delete!(keys)
    # end

    def flush
      keys = []
      FileUtils.mkdir_p @save_to_dir if  @save_to_dir
      Dir.mktmpdir do |dir|
        keys, tmpfile = save_pages_to(dir)
        cmd = "s3cmd put #{dir}/#{tmpfile} s3://#{s3bucket}/#{s3folder}/#{tmpfile}"
        system cmd if @save_to_s3
        FileUtils.mv(File.join(dir,tmpfile), @save_to_dir) if @save_to_dir
      end
      return keys
    end

    def flush!
      keys = flush
      delete!(keys)
    end

    def timestamp
      Time.now.getutc.to_s.gsub(/\s/,'').gsub(/:/,"-")
    end

    def save_pages_to(dir=".")
      tmpfile = "#{@s3name}.#{@worker_id}.#{timestamp}.jsons.gz".gsub(/:/,"-")
      filename = File.join(dir,tmpfile)
      Zlib::GzipWriter.open(filename) do |gz|
        keys.each do |k|
          gz.write @pages[k]
          gz.write "\n"
        end
      end
      return keys, tmpfile
    end

    # this is so dumb...can't ruby redis cli take a giant list of keys?
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
