#!/usr/bin/env ruby
#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content 
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#

require 'cloud-crawler/exceptions'
require 'cloud-crawler/redis_url_bloomfilter'
require 'trollop'
require 'redis'



module CloudCrawler
class TestBloomFilter
  
   def initialize(opts = {})
      p opts
      @redis = Redis.new(opts)
      @bloomfilter = RedisUrlBloomfilter.new(@redis,opts)
      @file  = opts[:file]
    end
    
   def run
     urls = []
     File.open(@file) do |f|
       f.each do |line|
         url = line.chomp.split(/\s/).first
         @bloomfilter.touch_url(url) if rand(10) < 5
         urls << url
       end
     end
     
     found_urls = []
     urls.each do |url|
         found_urls << url if  @bloomfilter.visited_url?(url)
     end
     
     puts "number urls = #{urls.size}, found urls = #{found_urls.size}"
   end


end
end


 
 
 

if __FILE__==$0 then
  opts = Trollop::options do
   opt :host,  "-h", :default => "localhost"
   opt :port, "-p", :default => 6379
   opt :file,  "-f", :default => "urls" 
  end
 CloudCrawler::TestBloomFilter.new(opts).run
end



   


