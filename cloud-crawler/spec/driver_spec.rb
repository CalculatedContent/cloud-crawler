#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content (TM)
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#
# All rights reserved.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL MADE BY MADE LTD BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'cloud-crawler/driver'
require 'cloud-crawler/redis_page_store'

#TODO: implement simple DSL tests
#  basic crawl
#  crawl with blocks
#  crawl options

#TODO: Problem:  redisdb completely flushed at every test run
#      need to namespace redis somehow ? 
#      to avoid blowing away the redis db when running rake on a prod machine
#

#TODO:  write a test to deal with local and master redis
#
module CloudCrawler
  describe Driver do

    before(:each) do
      FakeWeb.clean_registry
      @redis = Redis.new
      @redis.flushdb
      @opts = CloudCrawler::Driver::DRIVER_OPTS
      @page_store = RedisPageStore.new(@redis, @opts)
      @cache =  Redis::Namespace.new("#{@opts[:job_name]}:cache", :redis => @redis)
      @client = Qless::Client.new
      @queue = @client.queues[@opts[:queue_name]]
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
   #   pages << FakePage.new('2')
    #  pages << FakePage.new('3')  we dont need this page

      Driver.crawl(pages[0].url) do |a|
        a.focus_crawl do |p|
          p.all_links
        end
      end
      
      run_jobs
      @page_store.size.should == 4
    end
  

    it 'should support recuring crawl job'
    
       @opts[:recur] = 60
       # crawl some links
       # check size of page store
       # flush the db
       # wait
    
       # check size of pagestore again
       
    end
  

    it "should crawl all the html pages loaded as hashes" do
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'])
      pages << FakePage.new('1', :links => ['3'])
      pages << FakePage.new('2')
      pages << FakePage.new('3')

      Driver.crawl( {:url => pages[0].url} ) do |a|
        a.focus_crawl do |p|
          p.all_links
        end
      end
      
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
        a.on_every_page do 
          cache.incr "count" 
        end
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
