#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content (TM)
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#
# All rights reserved.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL MADE BY MADE LTD BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
require 'redis'
require 'redis-namespace'
require 'redis-caches/s3_cache'

require 'json'
require 'zlib'
require 'socket'

require 'cloud-crawler/logger'


#TODO  move S3 serialization to a seperate module
#  so it can be tested, re-used, and optmized everywhere we use redis
module CloudCrawler
  class RedisDocStore
    include Enumerable

    attr_reader :namespace

    def initialize(redis, opts={})
      @redis = redis
      @opts = opts
      @namespace =  make_namespace
            
      @docs = Redis::Namespace.new(@namespace, :redis => redis)
      @docs.s3_init(opts)   
    end

    def close
      @redis.quit
    end

 
    def [](id)
      rget(key_for id)
    end

    def []=(id, doc)
      rkey = key_for id
      @docs[rkey]= doc.to_json
    end

    def delete(id)
      page = self[id]
      @docs.del(key_for id)
      page
    end


    def has_key?(key)
      @docs.exists(key)
    end

    def each
      rkeys = @docs.keys("*")
      rkeys.each do |rkey|
        doc = rget(rkey)
        key = key_for doc, id
        yield key, doc
      end
    end

    def merge!(hash)
      hash.each { |key, value| self[key] = value }
      self
    end

    def size
      @docs.keys("*").size
    end

    def keys
      @docs.keys("*")
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
      @docs.s3.save!
    end
    
    def save
       @docs.s3.save
    end
    
    def delete!(keys)
      @docs.pipelined do
        keys.each { |k| @docs.del k }
      end
      return keys
    end

    # implement in base classes
    
    # really this should be a hash of a doc
     def key_for(id)
       id
     end
     
     def make_namespace
       "#{@opts[:job_name]}:docs"
     end
   
    def rget(rkey)
      JSON.parse(@docs[rkey])
    end    
  
  end
end
