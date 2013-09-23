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
     
    def self.init_with_pagestore(qless_job)   
      init_without_pagestore(qless_job)
      @page_store = RedisPageStore.new(@local_redis,@opts)
     # @http_cache={}
      @http = nil
      @page = nil
    end
     
    class << self
      alias_method_chain :init, :pagestore
    end
    
    def self.http
       @http
    end
    
    
    

    def self.process_job(job)
      LOGGER.info "processing curl job id #{job_id}"

      link, referer, depth = job[:link], job[:referer], job[:depth]
      
      return [] if link.nil? or link.empty? or link == :END

      # hack for cookies .. should be jid  is this correct?
      # VERY BAD
    #  @http_cache[job_id] ||=  CloudCrawler::HTTP.new(@opts)
     # @http=@http_cache[job_id]
      
       @http = CloudCrawler::HTTP.new(@opts)

      return [] if http.nil?
      
      fetched_pages = if keep_redirects? then
          http.fetch_pages(link, referer, depth) 
        else 
          [ http.fetch_page(link, referer, depth) ]
      end
      
      fetched_pages.flatten!
      fetched_pages.compact!

      fetched_pages.each do |page|
        next if page.nil?
        do_page_blocks(page)  #DSL  should optimize .. can i convert to a singleton method
      end

      fetched_pages.each do |page|
        # TODO:  normalize the url to avoid parameter shuffling
        url = page.url.to_s
        @page_store[url] = page unless @opts[:discard_page]
      end

 
      return []
    end

  end

end

#TODO: add timestamp to logging
#  test
