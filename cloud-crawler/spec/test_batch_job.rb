require 'rubygems'
require 'bundler/setup'
require 'qless'
require 'json'
require 'active_support/core_ext'

module CloudCrawler
  class TestBatchJob 


    attr_accessor :data, :client, :queue
    def initialize(opts, data)
      @client = Qless::Client.new
      @queue_name = opts[:queue_name] 
      @queue = @client.queues[@queue_name]
      
      @data = data     
      @data[:opts] = opts.to_json
    end

  end




end