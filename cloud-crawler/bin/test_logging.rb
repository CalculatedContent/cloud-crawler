#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'cloud-crawler'
require 'cloud-crawler/logger'

module CloudCrawler

  def CloudCrawler.log
    logger.info "test"
  end
  
end


CloudCrawler.log