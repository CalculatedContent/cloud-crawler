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

qurl = URI::encode("http://www.livestrong.com")

opts = Trollop::options do
  opt :urls, "urls to crawl", :short => "-u", :multi => true,  :default => qurl
  opt :job_name, "name of crawl", :short => "-n", :default => "word-count"
  opt :flush,  "", :short => "-f", :default => true
  opt :batch_size, "", :short => "-m", :default => 100

  opt :s3_bucket, "save intermediate results to s3 bucket",  :short => "-s", :default => "cc-examples"
  opt :keep_tmp_files, "save intermediate files to local dir", :short => "-t",  :type => :string, :default => nil

  opt :depth_limit, "limit the depth of the crawl", :short => "-l", :type => :int, :default => nil
  opt :discard_page_bodies, "discard page bodies after processing?",  :short => "-d", :default => true
  opt :skip_query_strings, "skip any link with a query string? e.g. http://foo.com/?u=user ",  :short => "-Q", :default => false
end

# classic word counting application
# unfornately master cache pipelining can not be turned on
# should is 
CloudCrawler::batch_crawl(opts[:urls], opts )  do |cc|

  cc.on_every_page do |page|
      # skip if page xml, or only process xml with crawler
      #  somehow xml slips in
      next unless page.document and page.document.title
      page.document.title.downcase.split(/\s/).each do |tok|
       s3_cache.incr(tok)
    end
  end
  
  
end

