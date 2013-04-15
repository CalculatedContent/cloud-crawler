$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'cloud-crawler/driver'
require 'cloud-crawler/redis_page_store'

#TODO: implement simple DSL tests
#  basic crawl
#  crawl with blocks
#  crawl options

module CloudCrawler
  describe Driver do

    before(:each) do
      FakeWeb.clean_registry
      @redis = Redis.new
      @redis.flushdb
      @opts = CloudCrawler::Driver::DRIVER_OPTS
      @page_store = RedisPageStore.new(@redis, @opts)
      @cache =  Redis::Namespace.new("#{@opts[:name]}:cache", :redis => @redis)
      @client = Qless::Client.new
      @queue = @client.queues[@opts[:name]]
    end

    after(:each) do
       @redis.flushdb
    end
    
    def run_jobs
      while qjob = @queue.pop
        qjob.perform
      end
    end

    #   shared_examples_for "crawl" do
    it "should crawl all the html pages in a domain by following <a> href's" do
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'])
      pages << FakePage.new('1', :links => ['3'])
      pages << FakePage.new('2')
      pages << FakePage.new('3')

      Driver.crawl(pages[0].url)
      run_jobs
      @page_store.size.should == 4
    end

    it "should be able to call a block on every page" do
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'])
      pages << FakePage.new('1')
      pages << FakePage.new('2')

      count = 0
      Driver.crawl(pages[0].url) do |a|
        a.on_every_page { cache.incr "count" }
      end

      run_jobs
      @cache["count"].should == "3"
    end

    it "should provide a focus_crawl method to select the links on each page to follow" do
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'])
      pages << FakePage.new('1')
      pages << FakePage.new('2')

      # note:  sourcify gets confused with multiple procs on the same line
      Driver.crawl(pages[0].url) do |a|
        a.focus_crawl do |p|
          p.links.reject do |l|
            l.to_s =~ /1/ end
        end
      end

      run_jobs
      @page_store.size.should == 2
      @page_store.keys.should include(pages[0].url.to_s)
      @page_store.keys.should_not include(pages[1].url.to_s)
    end

    describe "options" do
      it "should accept options for the crawl" do
        core = Driver.crawl(SPEC_DOMAIN,
        :verbose => false,
        :discard_page_bodies => true,
        :user_agent => 'test',
        :delay => 8,  # not implemented yet
        :obey_robots_txt => true,
        :depth_limit => 3)

        core.opts[:verbose].should == false
        core.opts[:discard_page_bodies].should == true
        core.opts[:user_agent].should == 'test'
        core.opts[:delay].should == 8
        core.opts[:obey_robots_txt].should == true
        core.opts[:depth_limit].should == 3
      end
    end

    it "should accept options via setter methods in the crawl block" do
      core = Driver.crawl(SPEC_DOMAIN) do |a|
        a.verbose = false
        a.discard_page_bodies = true
        a.user_agent = 'test'
        a.delay = 8
        a.obey_robots_txt = true
        a.depth_limit = 3
      end

      core.opts[:verbose].should == false
      core.opts[:discard_page_bodies].should == true
      core.opts[:delay].should == 8
      core.opts[:user_agent].should == 'test'
      core.opts[:obey_robots_txt].should == true
      core.opts[:depth_limit].should == 3
    end

  end
end
