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

url = URI::encode("http://www.livestrong.com")

opts = Trollop::options do
  opt :job_name, "name of crawl", :short => "-n", :default => "word-count"
  opt :batch_size, "size of bulk crawl job", :short => "-b", :default => 10

  opt :save_batch, "save bulk crawl job", :short => "-B", :default => false

  opt :delay, "delay between each http request (not batch jobs)",  :short => "-i", :default => 1
  opt :s3_bucket, "s3 bucket name, nil if not to save", :short => "-s", :default => "cloud-crawler"

  opt :depth_limit, "limit the depth of the crawl", :short => "-l", :type => :int, :default => 100
  opt :discard_page, "discard page  after processing?",  :short => "-d", :default => false

  opt :accept_cookies, "accept cookies", :short => "-C", :default => false
end
#Trollop::die :s3_bucket, "s3 bucket #{opts[:s3_bucket]} not found, please make first" if `s3cmd ls | grep "#{opts[:s3_bucket]}"`.empty?
Trollop::die :delay, "delay  #{opts[:delay]} must be > 0" if opts[:delay].nil? or  opts[:delay] < 1

job = {:url => URI::encode(url), :qid => 1 ,  :batch_id => 1 }  
batch = [job]

# classic word counting application
CloudCrawler::batch_crawl(batch, opts)  do |cc|

  cc.on_every_page do |page|
    next unless page.html? and page.document and page.document.title
    page.document.title.downcase.split(/\s/).each do |tok|
      m_cache.incr(tok)
    end
  end  
  
end

