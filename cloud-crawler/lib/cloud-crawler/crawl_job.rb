#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content (TN)
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
require 'cloud-crawler/redis_page_store'
require 'cloud-crawler/redis_url_bloomfilter'
require 'cloud-crawler/dsl_core'
require 'active_support/inflector'
require 'active_support/core_ext'

module CloudCrawler
  
  class CrawlJob
    include DslCore
  
    def self.init(qless_job)
      @namespace = @opts[:job_name] || 'cc'
      @queue_name = @opts[:queue_name] 
      @cache = Redis::Namespace.new("#{@namespace}:cache", :redis => qless_job.client.redis)
      @page_store = RedisPageStore.new(qless_job.client.redis,@opts)
      @bloomfilter = RedisUrlBloomfilter.new(qless_job.client.redis,@opts)
      @queue = qless_job.client.queues[@queue_name]   
      @depth_limit = @opts[:depth_limit]
    end
  
    def self.cache
      @cache
    end
  
    def self.perform(qless_job)
      super(qless_job)
      init(qless_job)
             
      data = qless_job.data.symbolize_keys
      link, referer, depth = data[:link], data[:referer], data[:depth]     
      return if link == :END     
                  
      http = CloudCrawler::HTTP.new(@opts)
      pages = http.fetch_pages(link, referer, depth)
      pages.each do |page|
         url = page.url.to_s
         next if @bloomfilter.visited_url?(url)

         do_page_blocks(page)
         
         links = links_to_follow(page)       
         links.each do |lnk|
            # next if lnk.to_s==url  # avoid loop
            next if @bloomfilter.visited_url?(lnk)  
            data[:link], data[:referer], data[:depth] =  lnk.to_s, page.referer.to_s, page.depth + 1 
            next if @depth_limit and data[:depth] > @depth_limit 
            @queue.put(CrawlJob, data)
         end
         
         page.discard_doc! if @opts[:discard_page_bodies]
         @page_store[url] = page   
         @bloomfilter.visit_url(url)

     end  
    end
   
  end

end