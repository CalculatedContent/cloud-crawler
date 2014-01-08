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
require 'cloud-crawler/redis_doc_store'
require 'cloud-crawler/dsl_core'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'redis-caches/s3_cache'

# Like a batch curl job, but returns json, not http
# allows for authentication via http party
module CloudCrawler
  class BatchApiJob < BatchJob
     
    def self.init_with_docstore(qless_job)   
      init_without_docstore(qless_job)
      @doc_store = RedisDocStore.new(@local_redis,@opts)
      @http = nil
      @page = nil
    end

    
    def self.http
       @http
    end
   

    def self.process_job(job)
      LOGGER.info "processing api job id #{job_id}"

      # TODO: we need http party and to authenticate
      
      @http = CloudCrawler::HttpParty.new(@opts)

      return [] if http.nil?
      
      fetched_jsons = []  # TODO: get the parsed json here

      fetched_jsons.each do |json|
        next if json.nil?
        do_json_blocks(json)  #DSL  have each_json
      end

      fetched_jsons.each do |json|
        id = json.hashcode  #TODO:  create or extrcat id 
        @doc_store[id] = json unless @opts[:discard_page]
      end

      return []
    end

    def self.do_pre_batch_with_auth
      LOGGER.info "do_pre_batch_with_auth" 
      do_pre_batch_without_auth
 
      # get the http auth and log in with http party
    end
    
    
    def self.do_post_batch_with_docstore
      LOGGER.info "do_pre_batch_with_api" 
      do_post_batch_without_docstore
      
     # if  save_page_store? then
      if save_batch? and !opts[:discard_page] then
        LOGGER.info " saving #{@doc_store.keys.size} pages into page store" 
        @saved_ids = @doc_store.save! 
      end
      
      # check bloomfilter, not yet

    end
    
 
 
    class << self
      alias_method_chain :init, :docstore
      alias_method_chain :do_post_batch, :docstore
      alias_method_chain :do_pre_batch, :auth
    end
    
    
    
  end

end

