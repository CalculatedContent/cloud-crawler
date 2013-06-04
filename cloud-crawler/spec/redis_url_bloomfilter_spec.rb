$:.unshift(File.dirname(__FILE__))
require 'spec_helper'


module CloudCrawler
  describe RedisPageStore do

    before(:all) do
      FakeWeb.clean_registry
    end

    # redis should be running locally
      before(:each) do
        @url = SPEC_DOMAIN
        @redis = Redis::Namespace.new("RedisUrlBloomfilterSpec", :redis => Redis.new)
        @bloomfilter = RedisUrlBloomfilter.new(@redis)
      end

      after(:each) do
        @redis.flushdb
      end
              
      it "should normalize https in urls " do
         @bloomfilter.key_for("https://www.google.com").should == "http://www.google.com"
      end

      
      it "should have a namespace" do
        @bloomfilter.should respond_to(:namespace)
      end
        
      it "should store urls in bloomfilter" do
        @bloomfilter.should respond_to(:touch_url)
        @bloomfilter.should respond_to(:touched_url?)

        @bloomfilter.touch_url(@url)
        @bloomfilter.touched_url?(@url).should == true
        @bloomfilter.touched_url?("test").should == false
        
        @bloomfilter.touch_urls( ["http://a","http://b","http://c"] )
        
      end
      
      it "alias touch to visit" do
        @bloomfilter.should respond_to(:visit_url)
        @bloomfilter.should respond_to(:visit_urls)
        @bloomfilter.should respond_to(:visited_url?)
      end
      
 

  end
end
