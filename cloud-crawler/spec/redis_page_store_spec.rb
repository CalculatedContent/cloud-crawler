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


module CloudCrawler
  describe RedisPageStore do

    before(:all) do
      FakeWeb.clean_registry
    end

    # redis should be running locally
      before(:each) do
        @url = SPEC_DOMAIN
        @opts = {}
        @opts.reverse_merge! CloudCrawler::Driver::DRIVER_OPTS
        @redis = Redis::Namespace.new("RedisPageStoreSpec", :redis => Redis.new)
        @store = RedisPageStore.new(@redis, @opts)
        @page = Page.new(URI(@url))
      end

      after(:each) do
        @store.close
        @redis.flushdb
      end
              
      it "should normalize https in urls " do
         @store.key_for("https://www.google.com").should == "http://www.google.com"
      end

      it "should implement [] and []=" do
        @store.should respond_to(:[])
        @store.should respond_to(:[]=)

        @store[@url] = @page
        @store[@url].url.should == URI(@url)
      end

      it "should implement has_page?" do
        @store.should respond_to(:has_page?)

        @store[@url] = @page
        @store.has_page?(@url).should == true

        @store.has_page?('missing').should == false
      end

      it "should implement delete" do
        @store.should respond_to(:delete)

        @store[@url] = @page
        @store.delete(@url).url.should == @page.url
        @store.has_page?(@url).should  == false
      end
      
    
      
     
      
      # it "should implement keys" do
      # @store.should respond_to(:keys)
      #
      # urls = [SPEC_DOMAIN, SPEC_DOMAIN + 'test', SPEC_DOMAIN + 'another']
      # pages = urls.map { |url| Page.new(URI(url)) }
      # urls.zip(pages).each { |arr| @store[arr[0]] = arr[1] }
      #
      # (@store.keys - urls).should == []
      # end
      #
      # it "should implement each" do
      # @store.should respond_to(:each)
      #
      # urls = [SPEC_DOMAIN, SPEC_DOMAIN + 'test', SPEC_DOMAIN + 'another']
      # pages = urls.map { |url| Page.new(URI(url)) }
      # urls.zip(pages).each { |arr| @store[arr[0]] = arr[1] }
      #
      # result = {}
      # @store.each { |k, v| result[k] = v }
      # (result.keys - urls).should == []
      # (result.values.map { |page| page.url.to_s } - urls).should == []
      # end
      #
      # it "should implement merge!, and return self" do
      # @store.should respond_to(:merge!)
      #
      # hash = {SPEC_DOMAIN => Page.new(URI(SPEC_DOMAIN)),
      # SPEC_DOMAIN + 'test' => Page.new(URI(SPEC_DOMAIN + 'test'))}
      # merged = @store.merge! hash
      # hash.each { |key, value| @store[key].url.to_s.should == key }
      #
      # merged.should === @store
      # end

      # it "should correctly deserialize nil redirect_to when loading" do
        # @page.redirect_to.should be_nil
        # @store[@url] = @page
        # @store[@url].redirect_to.should be_nil
      # end
# 
    # end
  #
  # it "should be able to compute single-source shortest paths in-place" do
  # pages = []
  # pages << FakePage.new('0', :links => ['1', '3'])
  # pages << FakePage.new('1', :redirect => '2')
  # pages << FakePage.new('2', :links => ['4'])
  # pages << FakePage.new('3')
  # pages << FakePage.new('4')
  #
  # # crawl, then set depths to nil
  # page_store = CloudCrawler.crawl(pages.first.url, @opts) do |a|
  # a.after_crawl do |ps|
  # ps.each { |url, page| page.depth = nil; ps[url] = page }
  # end
  # end.pages
  #
  # page_store.should respond_to(:shortest_paths!)
  #
  # page_store.shortest_paths!(pages[0].url)
  # page_store[pages[0].url].depth.should == 0
  # page_store[pages[1].url].depth.should == 1
  # page_store[pages[2].url].depth.should == 1
  # page_store[pages[3].url].depth.should == 1
  # page_store[pages[4].url].depth.should == 2
  # end
  #
  # it "should be able to remove all redirects in-place" do
  # pages = []
  # pages << FakePage.new('0', :links => ['1'])
  # pages << FakePage.new('1', :redirect => '2')
  # pages << FakePage.new('2')
  #
  # page_store = CloudCrawler.crawl(pages[0].url, @opts).pages
  #
  # page_store.should respond_to(:uniq!)
  #
  # page_store.uniq!
  # page_store.has_key?(pages[1].url).should == false
  # page_store.has_key?(pages[0].url).should == true
  # page_store.has_key?(pages[2].url).should == true
  # end
  #
  # it "should be able to find pages linking to a url" do
  # pages = []
  # pages << FakePage.new('0', :links => ['1'])
  # pages << FakePage.new('1', :redirect => '2')
  # pages << FakePage.new('2')
  #
  # page_store = CloudCrawler.crawl(pages[0].url, @opts).pages
  #
  # page_store.should respond_to(:pages_linking_to)
  #
  # page_store.pages_linking_to(pages[2].url).size.should == 0
  # links_to_1 = page_store.pages_linking_to(pages[1].url)
  # links_to_1.size.should == 1
  # links_to_1.first.should be_an_instance_of(Page)
  # links_to_1.first.url.to_s.should == pages[0].url
  # end
  #
  # it "should be able to find urls linking to a url" do
  # pages = []
  # pages << FakePage.new('0', :links => ['1'])
  # pages << FakePage.new('1', :redirect => '2')
  # pages << FakePage.new('2')
  #
  # page_store = CloudCrawler.crawl(pages[0].url, @opts).pages
  #
  # page_store.should respond_to(:pages_linking_to)
  #
  # page_store.urls_linking_to(pages[2].url).size.should == 0
  # links_to_1 = page_store.urls_linking_to(pages[1].url)
  # links_to_1.size.should == 1
  # links_to_1.first.to_s.should == pages[0].url
  # end
  # end

  end
end
