#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'cloud-crawler'
require 'trollop'
require 'open-uri'

qurl = URI::encode("http://www.ebay.com/sch/&_nkw=digital+camera")

opts = Trollop::options do
  opt :urls, "urls to crawl", :short => "-u", :multi => true,  :default => qurl
  opt :name, "name of crawl", :short => "-n", :default => "find_404s"  # does not work yet
  opt :flush,  "", :short => "-f", :default => true
  opt :max_slice, "", :short => "-m", :default => 10
  
  opt :s3_bucket, "save intermediate results to s3 bucket",  :short => "-s", :default => "cc-examples"
  opt :keep_tmp_files, "save intermediate files to local dir", :short => "-t",  :type => :string, :default => false

  opt :depth_limit, "limit the depth of the crawl", :short => "-l", :type => :int, :default => 1 
  opt :discard_page_bodies, "discard page bodies after processing?",  :short => "-d", :default => true
  opt :skip_query_strings, "skip any link with a query string? e.g. http://foo.com/?u=user ",  :short => "-Q", :default => false
end


# simple example of SEO tool
# Find all the pages on the website that contain links to the 404s
#  
CloudCrawler::crawl(opts[:urls], opts)  do |cc|
  
 cc.on_every_page do |page|
    if page.code == 404 then     
      s3_cache["404url:#{page.url.to_s}"]=1
      s3_cache["404ref:#{page.referer}:#{page.url.to_s}"]=1
    end
  end
end

