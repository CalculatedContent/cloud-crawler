#!/usr/bin/env ruby
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
require 'rubygems'
require 'bundler/setup'
require 'cloud-crawler'
require 'trollop'
require 'open-uri'

qurl = URI::encode("http://www.ebay.com/sch/&_nkw=digital+camera")

opts = Trollop::options do
  opt :urls, "urls to crawl", :short => "-u", :multi => true,  :default => qurl
  opt :job_name, "name of crawl", :short => "-n", :default => "not-ready"  # does not work yet
  opt :flush,  "", :short => "-f", :default => true
  opt :batch_size, "", :short => "-m", :default => 100
  
   opt :s3_bucket, "save intermediate results to s3 bucket",  :short => "-s", :default => "cc-examples"
  opt :keep_tmp_files, "save intermediate files to local dir", :short => "-t",  :type => :string, :default => false
  
  opt :depth_limit, "limit the depth of the crawl", :short => "-l", :type => :int, :default => 1 
  opt :discard_page, "discard page bodies after processing?",  :short => "-d", :default => true
  opt :skip_query_strings, "skip any link with a query string? e.g. http://foo.com/?u=user ",  :short => "-Q", :default => false
end


# Count all words in the titles of the pages
#  sync the local data to redis master when done

#  ideally, a counter
CloudCrawler::batch_crawl(opts[:urls], opts)  do |cc|
  
  cc.on_every_page do |page|
    
    local_cache.pipelined do
      page.document.title.downcase.split(/\s/).each do |tok|
        local_cache.incr(tok)
      end
    end
    
  end
  
  # sync local counters to the master cache  after every crawl
  #  sync_local_counters
  
  cc.after_batch_job do |me|
    master_cache.pipelined do
      local_cache.keys do |k|
        val = local_cache[k]
        master_cache.incr(k,val)
      end
    end
  end
  
end

