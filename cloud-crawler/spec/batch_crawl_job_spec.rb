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
require 'redis'
require 'cloud-crawler/batch_crawl_job'
require 'cloud-crawler/batch_job'
require 'test_batch_job'
require 'sourcify' #,'~> 0.6'  

module CloudCrawler
  
  describe BatchCrawlJob do

    before(:each) do
      FakeWeb.clean_registry
      @redis = Redis.new
      @redis.flushdb
      @opts = CloudCrawler::Driver::DRIVER_OPTS
      @opts.reverse_merge! CloudCrawler::DEFAULT_OPTS
      @opts[:save_batch]= false
     
      @namespace = @opts[:job_name]
      @w_cache = Redis::Namespace.new("#{@namespace}:w_cache", :redis => @redis)
      @ccmq =  Redis::Namespace.new("#{@namespace}:ccmq", :redis => @redis)

      @page_store = RedisPageStore.new(@redis, @opts)
      @bloomfilter = RedisUrlBloomfilter.new(@redis)
      
    end
    
   
    after(:each) do
       @redis.flushdb
    end
    
    
        
    
    def crawl_link(urls, blocks={})
      
      qless_job = TestBatchJob.new(urls, opts=@opts, ccmq=@ccmq, blocks=blocks)
      CloudCrawler::BatchCrawlJob.perform(qless_job)
      while qless_job = qless_job.queue.pop
        qless_job.perform
      end
            
      return @page_store.size
    end
    
 
    
    

  

    it "should crawl all the html pages in a domain by following <a> href's" do 
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'])
      pages << FakePage.new('1', :links => ['3'])
      pages << FakePage.new('2')
      pages << FakePage.new('3')
      
      crawl_link(pages[0].url).should == 4

    end
    
    
        
    it "should crawl all the html pages as a list of urls" do
      pages = []
      pages << FakePage.new('0')
      pages << FakePage.new('1')
      pages << FakePage.new('2')
      pages << FakePage.new('3')
      
      urls = pages.map { |x| x.url.to_s }
      crawl_link(urls).should == urls.size
      
    end
    
    it "should follow http redirects" do
      pages = []
      pages << FakePage.new('0', :links => ['1'])
      pages << FakePage.new('1', :redirect => '2')
      pages << FakePage.new('2')

      crawl_link(pages[0].url).should == 3
    end
    
    it "should not follow links that leave the original domain" do
      pages = []
      pages << FakePage.new('0', :links => ['1'], :hrefs => 'http://www.other.com/')
      pages << FakePage.new('1')

      crawl_link(pages[0].url).should == 2
      @page_store.keys.should_not include('http://www.other.com/')
    end

    it "should not follow redirects that leave the original domain" do
      pages = []
      pages << FakePage.new('0', :links => ['1'], :redirect => 'http://www.other.com/')
      pages << FakePage.new('1')

      crawl_link(pages[0].url).should == 2
      @page_store.keys.should_not  include('http://www.other.com/')
    end



    it "should follow http redirects" do
      pages = []
      pages << FakePage.new('0', :links => ['1'])
      pages << FakePage.new('1', :redirect => '2')
      pages << FakePage.new('2')

      crawl_link(pages[0].url).should == 3
    end
    
     it "should include the query string when following links" do
      pages = []
      pages << FakePage.new('0', :links => ['1?foo=1'])
      pages << FakePage.new('1?foo=1')
      pages << FakePage.new('1')

      crawl_link(pages[0].url).should == 2
      @page_store.keys.should  include(pages[0].url.to_s)
      @page_store.keys.should_not  include(pages[2].url.to_s)
    end
    
    it "should follow with HTTP basic authentication" do
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'], :auth => true)
      pages << FakePage.new('1', :links => ['3'], :auth => true)
     
      crawl_link(pages.first.auth_url).should == 3
    end

  
 


 
   
    it "should not discard page bodies by default" do
      crawl_link(FakePage.new('0').url).should == 1
      @page_store.values.first.doc.should_not be_nil
    end

    it "should optionally discard page bodies to conserve memory" do
      @opts[:discard_page] = true
      crawl_link(FakePage.new('0').url)
      @page_store.values.should be_empty
    end
    
     it "should optionally discard page bodies to conserve memory" do
      @opts[:discard_page] = false
      crawl_link(FakePage.new('0').url)
      @page_store.values.first.doc.should_not be_nil
    end

    it "should be able to call a block on every page, with access to a shared cache" do
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'])
      pages << FakePage.new('1')
      pages << FakePage.new('2')

      b = {:on_every_page_block => Proc.new { w_cache.incr "count" }.to_source }
      crawl_link(pages[0].url,blocks=b)
      @w_cache.get("count").should == "3"
    end

    it "should provide a focus_crawl method to select the links on each page to follow" do
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'])
      pages << FakePage.new('1')
      pages << FakePage.new('2')

      b = {:focus_crawl_block => Proc.new { page.links.reject{|l| l.to_s =~ /1/ }}.to_source }
      crawl_link(pages[0].url,blocks=b).should == 2
      @page_store.keys.should_not include(pages[1].url.to_s)
      @page_store.keys.should include(pages[0].url.to_s)
      @page_store.keys.should include(pages[2].url.to_s)
    end
    
    it "should be able to skip links based on a RegEx" do
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'])
      pages << FakePage.new('1')    
      pages << FakePage.new('2')
      pages << FakePage.new('3')
      
      # convert pattern to source
      b = {:skip_link_patterns => [/1/,/3/].map!{|x| x.source } }
      crawl_link(pages[0].url,blocks=b).should == 2
      
    end

    it "should optionally obey the robots exclusion protocol" do
      pages = []
      pages << FakePage.new('0', :links => '1')
      pages << FakePage.new('1')
      pages << FakePage.new('robots.txt',
      :body => "User-agent: *\nDisallow: /1",
      :content_type => 'text/plain')

      @opts[:obey_robots_txt] = true
      crawl_link(pages[0].url)
      urls = @page_store.keys
      urls.should include(pages[0].url)
      urls.should_not include(pages[1].url)
    end
# 
    describe "many pages" do
      before(:each) do
        @pages, size = [], 5
        size.times do |n|
        # register this page with a link to the next page
          link = (n + 1).to_s if n + 1 < size
          @pages << FakePage.new(n.to_s, :links => Array(link))
        end
      end

      it "should be able to set cookies to send with HTTP requests" do
        @opts[:cookies]  = {:a => '1', :b => '2'}
        crawl_link(@pages[0].url)
      end

      it "should track the page depth and referer" do
        crawl_link(@pages[0].url)
        previous_page = nil

        @pages.each_with_index do |page, i|
          page = @page_store[page.url.to_s]
          puts page.referer
        end

     #TODO:  figure out what this was supposed to be
      # page.depth.should == i
      # if previous_page then
      # page.referer.to_s.should == previous_page.url.to_s
      # else
      # page.referer.should == ""  # not nil ... could be an issue
      # end
      # previous_page = page
      # end
       end

   end
   
   
     #TODO ASAP:  fix bloomfilter tests
     
      # it "should crawl all the html pages and populate the bloom filter" do
       # pages = []
      # pages << FakePage.new('0', :links => ['1', '2'])
      # pages << FakePage.new('1', :links => ['3'])
      # pages << FakePage.new('2')
      # pages << FakePage.new('3')
#       
      # crawl_link(pages[0].url).should == 4
#       
       # pages.each do |p|
         # @bloomfilter.visited_url?(p.url).should be_true
       # end
     # end
     
     #
    # it "should  not crawl pages in the bloom filter" do
      # pages = []
      # pages << FakePage.new('0', :links => ['1', '2'])
      # pages << FakePage.new('1', :links => ['3'])
      # pages << FakePage.new('2')
      # pages << FakePage.new('3')
#       
      # @bloomfilter.visit_url(pages[3].url.to_s).should be_true
      # @bloomfilter.visited_url?(pages[3].url.to_s).should be_true
# 
      # crawl_link(pages[0].url).should == 3
#       
      # pages.each do |p|
         # @bloomfilter.visited_url?(p.url).should be_true
      # end
# 
    # end
# 


      # TODO:  implement this test properly
      it "should optionally limit the depth of the crawl" do
     #   @opts[:depth_limit] = 3
      #  crawl_link(@pages[0].url).should == 3 # ??
      end
    
    # TODO:  implement this test
    it "should create a list of next jobs based on the input batch" do
      
    end
    
     # TODO:  implement this test
    it "should not recrawl a url if it is in the bloomfilter" do
      
    end
    
    # TODO:  implement this test
    it "should save the results in the page store" do
      
    end
    
    # TODO:  implement this test
    it "should save the results in the page store" do
      
    end
    
     # TODO:  implement this test
    it "retain data, like user_agent, in the next_jobs from the parent job" do
      
    end
    
     # TODO:  implement this test
    it "optionally drop a cookie and re-use it in the next job" do
      
    end
    
    # TODO:   implement this test
    it 'should normalize the url, or use some other key, for the pagestore' do
      
    end
    
    
      
    
    
   
   

  end
end
