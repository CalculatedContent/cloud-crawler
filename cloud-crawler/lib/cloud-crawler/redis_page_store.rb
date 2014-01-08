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
require 'cloud-crawler/redis_doc_store'
require 'cloud-crawler/logger'


#TODO  move S3 serialization to a seperate module
#  so it can be tested, re-used, and optmized everywhere we use redis
module CloudCrawler
  class RedisPageStore < RedisDocStore

    MARSHAL_FIELDS = %w(links visited fetched)
   
    # url encode or decode url for keys?
    def key_for(url)
      url.to_s.downcase.gsub("https",'http').gsub(/\s+/,' ')
    end

    def rget(rkey)
      json = JSON.parse(@docs[rkey])
      Page.from_hash(json)
    end

    def []=(id, page)
      rkey = key_for id
      @docs[rkey]= page.to_hash.to_json
    end
    
    def has_page?(key)
      has_key?(key_for key)
    end
    
  end
end
