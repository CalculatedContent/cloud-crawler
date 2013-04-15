#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'cloud-crawler'
require 'trollop'


opts = Trollop::options do
  opt :urls, "urls to crawl", :short => "-u", :multi => true,  :default => "http://www.ehow.com"
end


CloudCrawler::crawl(opts[:urls], {}) do |crawl|
  crawl.on_every_page do |p|
    cache.incr "count"
  end
end
