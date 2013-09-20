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
require 'rubygems'
require 'bundler/setup'
require 'qless'
require 'json'
require 'active_support/core_ext'

module CloudCrawler
  module MakeTestBlocks
    

    def self.make_test_blocks(ccmq, blocks={})
      blocks[:focus_crawl_block] ||= nil
      blocks[:on_every_page_block] ||= nil
     
      blocks[:before_crawl_block] ||= nil
      blocks[:after_crawl_block] ||= nil
      blocks[:before_batch_block] ||= nil
      blocks[:after_after_block] ||= nil
      
      blocks[:skip_link_patterns] ||=  []
      blocks[:on_pages_like_blocks] ||= Hash.new { |hash,key| hash[key] = [] }
      
      json = blocks.to_json
      id = "12345" #json.hash  can not use hash, need different id
      ccmq["dsl_blocks:#{id}"]=json
      
          puts  "test blocks #{id} =>#{blocks}"

      
      return id
    end
    
  end
end