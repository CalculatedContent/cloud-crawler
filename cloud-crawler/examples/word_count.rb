#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'cloud-crawler'
require 'trollop'
require 'open-uri'

qurl = URI::encode("http://www.ebay.com/sch/&_nkw=digital+camera")

opts = Trollop::options do
  opt :urls, "urls to crawl", :short => "-u", :multi => true,  :default => qurl
  opt :name, "name of crawl", :short => "-n", :default => "word-count"  # does not work yet
  opt :flush,  "", :short => "-f", :default => true
  opt :max_slice, "", :short => "-m", :default => 1000

  opt :s3_bucket, "save intermediate results to s3 bucket",  :short => "-s", :default => "cc-examples"
  opt :keep_tmp_files, "save intermediate files to local dir", :short => "-t",  :type => :string, :default => false

  opt :depth_limit, "limit the depth of the crawl", :short => "-l", :type => :int, :default => 1 
  opt :discard_page_bodies, "discard page bodies after processing?",  :short => "-d", :default => true
  opt :skip_query_strings, "skip any link with a query string? e.g. http://foo.com/?u=user ",  :short => "-Q", :default => false
end


# Count all words in the titles of the pages
#  sync the local data to redis master when done

#  ideally, a counter
CloudCrawler::batch_crawl(opts[:urls], opts)  do |cc|
  
  
  cc.on_every_page do |page|  
    page.document.title.downcase.split(/\s/).each do |tok|
       m_cache.incr(tok)
    end
    
  end

  
end

