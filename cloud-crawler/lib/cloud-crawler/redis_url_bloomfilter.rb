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
require 'bloomfilter-rb'
require 'json'
require 'zlib'
require 'cloud-crawler/logger'

    
module CloudCrawler
   
   #TODO: replace with lua bloomfilter
  class RedisUrlBloomfilter
    include Enumerable
    
    attr_reader :namespace
    attr_accessor :disabled
    
    def initialize(redis, opts = {})
      @redis = redis
      @namespace = opts[:job_name] || 'cc'
 
      items, bits = 100_000, 5
      opts[:size] ||= items*bits
      opts[:hashes] ||= 7
      opts[:namespace] = "#{name}"
      opts[:db] = redis
      opts[:seed] = 1364249661
            
      # default is false
      @disabled =  opts[:disabled] || false
       
      
      # 2.5 mb? 
     @bloomfilter = BloomFilter::Redis.new(opts)
    end

    # really a bloom filter for anything with sugar
    def name
      "#{@namespace}:bf"
    end

    def enabled?
      true if @disabled.nil? or not @disabled
      false
    end
    
    def disabled?
      @disabled
    end
    
    # same as page store
    #TODO:  normalize urls when parameters are present
    # i.e: "http://www.bodybuilding.com/fun/bbinfo.php/?order=AUTHOR&page=WeiderPrinciples"
    def key_for(url)
      url.to_s.downcase.gsub("https",'http').gsub(/\s+/,' ')
    end
    
    
   
    
    # bloom filter methods
   
    def insert(url)
     return if disabled?
     @bloomfilter.insert(key_for url)
    end
    alias_method :visit_url, :insert
    alias_method :touch_url, :insert


    def touch_urls(urls)
      return if disabled?
      urls.each { |u| touch_url(u) }
    end
    alias_method :visit_urls, :touch_urls 


    def include?(url)
      return true if disabled?
      @bloomfilter.include?(key_for url)
    end
    alias_method :visited_url?, :include?
    alias_method :touched_url?, :include? 
    
    
    def not_include?(url)
      return !include?(url)
    end
    alias_method :not_visited_url?, :not_include?
    alias_method :not_touched_url?, :not_include? 

  end
end
