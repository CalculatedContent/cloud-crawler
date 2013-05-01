#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'cloud-crawler'
require 'trollop'
require 'open-uri'

qurl = URI::encode("http://www.ebay.com/sch/&_nkw=digital+camera")

opts = Trollop::options do
  opt :urls, "urls to crawl", :short => "-u", :multi => true,  :default => qurl
  opt :name, "name of crawl", :short => "-n", :default => "count_listings"  # does not work yet
  opt :flush,  "", :short => "-f", :default => true
  opt :max_slice, "", :short => "-m", :default => 10
 
  opt :s3_bucket, "save intermediate results to s3 bucket",  :short => "-s", :type => :string, :default => "cc-examples"
  opt :keep_tmp_files, "save intermediate files to local dir", :short => "-t",  :type => :string, :default => nil

  opt :depth_limit, "limit the depth of the crawl", :short => "-l", :type => :int, :default => 1 
  opt :discard_page_bodies, "discard page bodies after processing?",  :short => "-d", :default => true
  opt :skip_query_strings, "skip any link with a query string? e.g. http://foo.com/?u=user ",  :short => "-Q", :default => false
end


# Crawl digital camera listings on the first page of eBay
#  select links by  xpath
#  
CloudCrawler::batch_crawl(opts[:urls], opts)  do |cc|
  
  cc.focus_crawl do |page|
    page.select_links_by("//h4/a[@href]").each do |lnk|
      puts "lnk -->  #{lnk}"
    end
  end
  
end

