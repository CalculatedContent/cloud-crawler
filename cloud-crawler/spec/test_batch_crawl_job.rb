require 'rubygems'
require 'bundler/setup'
require 'qless'
require 'json'
require 'active_support/core_ext'

module CloudCrawler
  class TestBatchCrawlJob 


    attr_accessor :data, :client, :queue
    def initialize(links, opts, blocks)
      @client = Qless::Client.new
      @queue_name = opts[:queue_name] 
      @queue = @client.queues[@queue_name]
      
      @data = {}
      @data[:opts] = opts.to_json     
      @data[:focus_crawl_block] = [].to_json
      @data[:on_every_page_blocks] = [].to_json
      @data[:skip_link_patterns] =  [].to_json  
      @data[:on_pages_like_blocks] = Hash.new { |hash,key| hash[key] = [] }.to_json
      @data.merge! blocks 
         
      @data[:batch] = [links].flatten.map { |lnk|  { :link =>  lnk, :depth => 0 } }.to_json
    end

  end




end