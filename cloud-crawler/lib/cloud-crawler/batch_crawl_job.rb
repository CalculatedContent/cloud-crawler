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

module CloudCrawler
  class BatchCrawlJob < BatchJob
        
    def self.init_with_pagestore(qless_job)   
      @page_store = RedisPageStore.new(@local_redis,@opts)
      @bloomfilter = RedisUrlBloomfilter.new(@redis)
  #    @http_cache={}
      @http=nil
      init_without_pagestore(qless_job)
    end
    
    
    def self.visit_link_with_bloomfilter?(link, from_page = nil) 
        visit = visit_link_without_bloomfilter?(link, from_page)  
        return visit if recrawl? link  
        return visit && !@bloomfilter.visited_url?(link)
    end
    
    def self.recrawl?(link)
      false
    end
    
    
     
    class << self
      alias_method_chain :init, :pagestore
      alias_method_chain :visit_link?, :bloomfilter
    end
    
        
     
    def self.http
       @http
    end

    # (A) memory optimization
    #
    # pre_batch(batch)
    #   get links from ccmq
    #   either from a list or lookup in hashes
    
    
    #  get_link
    #    links.pop
    
    #  next_link
    #    
    def self.process_job(job)
      LOGGER.info "processing job #{job}"
      next_jobs = []

      #TODO: place links in a high performance cache
      #  link, referer, depth = get_link
      link, referer, depth = job[:link], job[:referer], job[:depth]
      
      return next_jobs if link.nil? or link.empty? or link == :END
      return next_jobs if @bloomfilter.visited_url?(link.to_s)

      # hack for cookies 
      # belongs in batch job itself
      
      # @http_cache[job_id] ||=  CloudCrawler::HTTP.new(@opts)
      # @http=@http_cache[job_id]
      
      @http = CloudCrawler::HTTP.new(@opts)
      
      return next_jobs if http.nil?
      
      fetched_pages = if keep_redirects? then
          http.fetch_pages(link, referer, depth) 
        else 
          [ http.fetch_page(link, referer, depth) ]
      end

      fetched_pages.flatten!
      fetched_pages.compact!
      fetched_pages.each do |page|
        # TODO:  Fecnh idea :  normalize the url to avoid parameter shuffling
        url = page.url.to_s

        do_page_blocks(page)    # DSL

        links = links_to_follow(page)    # DSL
        
        # links.reject! { |lnk| @bloomfilter.visited_url?(lnk) }  # in the dsl  
        links.each do |lnk|
          # next if lnk.to_s==url  # avoid loop
          next if depth_limit and (page.depth + 1 > depth_limit)
          #next_job = { :link => lnk.to_s, :referer => page.referer.to_s, :depth => page.depth + 1}
          next_job = { :link => lnk.to_s, :referer => url , :depth => page.depth + 1}
          next_job.reverse_merge!(job)
          next_jobs << next_job
        end
    
        @page_store[url] = page unless opts[:discard_page]
      end

      # must optionally turn off caching for testing

      # TODO;  mark bloom filter now?
      next_jobs.flatten!
      next_jobs.compact!

      return next_jobs
    end

  end
     
    def self.do_post_batch
      super()
      do_post_batch_without_pagestore
      LOGGER.info " saving #{@page_store.keys.size} pages intp page store" 
      saved_urls = @page_store.s3.save! 
 
      # add pages to bloomfilter only if store to s3 succeeds
      # skip root page?
      
      saved_urls.each { |url|  @bloomfilter.visit_url(url) }     
    end
    
 
    

end

