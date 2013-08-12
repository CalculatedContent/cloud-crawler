#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content 
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#
$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'redis'
require 'cloud-crawler/batch_curl_job'
require 'cloud-crawler/batch_job'
require 'test_batch_job'
require 'sourcify' #,'~> 0.6'  

module CloudCrawler
  
  
  #TODO:  combine this test with the batch crawl test
  # since they both need this functionality
  # alot of this is duplicated
  
  describe BatchCurlJob do

    before(:each) do
      FakeWeb.clean_registry
      @redis = Redis.new
      @redis.flushdb
      @opts = CloudCrawler::Driver::DRIVER_OPTS
      @opts.reverse_merge! CloudCrawler::DEFAULT_OPTS
      @opts[:save_batch]= false
     
      @namespace = @opts[:job_name]
      @w_cache = Redis::Namespace.new("#{@namespace}:w_cache", :redis => @redis)
      
      @page_store = RedisPageStore.new(@redis, @opts)
      @bloomfilter = RedisUrlBloomfilter.new(@redis)
      
    end
    
   
    after(:each) do
       @redis.flushdb
    end
    
    
    
    #
    # Create an object that behaves like a qless job for testing purposes
    # Perform job as if we are a simple worker in the same process
    #  
    def crawl_link(urls, blocks={})
      
      qless_job = TestBatchJob.new(urls, opts=@opts, blocks=blocks)
      CloudCrawler::BatchCurlJob.perform(qless_job)
      while qless_job = qless_job.queue.pop
        qless_job.perform
      end
            
      return @page_store.size
    end
    
   
    
    it "should crawl 1 html pages but not follow any links" do
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'])
      pages << FakePage.new('1', :links => ['5'])
      pages << FakePage.new('2')
      pages << FakePage.new('3')
      
      crawl_link(pages.map(&:url)).should == 4
    end


    it "should not discard page bodies by default" do
      crawl_link(FakePage.new('0').url).should == 1
      @page_store.values.first.doc.should_not be_nil
    end

    it "should optionally keep page bodies" do
      @opts[:discard_page] = true
      crawl_link(FakePage.new('0').url)
      @page_store.values.should be_empty
    end
    
     # redundant, but here incase the default options change
     it "should optionally discard page bodies to conserve memory" do
      @opts[:discard_page] = false
      crawl_link(FakePage.new('0').url)
      @page_store.values.first.doc.should_not be_nil
    end

    it "should be able to call a block on every page, with access to a shared cache" do
      pages = []
      pages << FakePage.new('0', :links => ['1', '2'])
      pages << FakePage.new('1', :links => ['5', '6'])
      pages << FakePage.new('2')
      pages << FakePage.new('3')
      
      # TODO: solv eproblem of to get the state back -- it is not persisted in the run
      # need to persist to redis or page-store
      
      b = {:on_every_page_blocks => [Proc.new { w_cache.incr "count" }.to_source].to_json }
      crawl_link(pages.map(&:url),b).should == 4
      @w_cache.get("count").should == "4"
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
    
    
    
     #TODO:  fix this
    # it "should follow with HTTP basic authentication" do
      # pages = []>
      # pages << FakePage.new('0', :links => ['1', '2'], :auth => true)
      # pages << FakePage.new('1', :links => ['3'], :auth => true)
# 
#      
      # crawl_link(pages.first.auth_url).should == 3
    # end



     # TODO:  implement this test
    it "should create a list of next jobs based on the input batch" do
      
    end
    
    
    # TODO:  implement this test
    it "should save the results in the page store" do
      
    end
    
    # TODO:   implement this test ... French idea
    it 'should normalize the url, or use some other key, for the pagestore' do
      
    end
    
    # TODO:   implement this test
    it 'should crawl all the links given, without any duplicates' do
      
    end


  end
end
