#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'cloud-crawler'
require 'trollop'
require 'open-uri'

qurl = URI::encode("http://www.crossfit.com")

opts = Trollop::options do
  opt :urls, "urls to crawl", :short => "-u", :multi => true,  :default => qurl
  opt :name, "name of crawl", :short => "-n", :default => "crawl"  # does not work yet
  opt :flush,  "", :short => "-f", :default => true
  opt :max_slice, "", :short => "-m", :default => 100
  opt :save_to_s3, "", :short => "-p", :default => false
  opt :depth_limit, "limit the depth of the crawl", :short => "-l", :type => :int, :default => 2
  opt :discard_page_bodies, "discard page bodies after processing?",  :short => "-d", :default => true
  opt :skip_query_strings, "skip any link with a query string? e.g. http://foo.com/?u=user ",  :short => "-Q", :default => false

  # only crawl outside links
  opt :outside_domain, "allow links outside of the root domain", :short => "-U", :default => true
  opt :inside_domain, "allow links inside of the root domain", :short => "-T", :default => false
end


# find all level 1 certs on the crossfit main site

CloudCrawler::crawl(opts[:urls], opts)  do |cc|
  
  cc.focus_crawl do |page|
    page.links.keep_if do |lnk| 
       text_for lnk =~ /Level 1/i
    end
  end

   cc.on_every_page do |page|
     puts page.url.to_s
   end
  
end

