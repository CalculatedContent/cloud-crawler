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
  describe RedisUrlBloomfilter do

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

    it "should store a  url in the bloomfilter" do
      @bloomfilter.should respond_to(:touch_url)
      @bloomfilter.should respond_to(:touched_url?)

      @bloomfilter.touch_url(@url)
      @bloomfilter.touched_url?(@url).should == true
      @bloomfilter.touched_url?("test").should == false

      @bloomfilter.touch_urls( ["http://a","http://b","http://c"] )

    end

    it "alias touch to visit" do
      @bloomfilter.should respond_to(:include?)
      @bloomfilter.should respond_to(:visit_url)
      @bloomfilter.should respond_to(:visit_urls)
      @bloomfilter.should respond_to(:visited_url?)
    end

    it "should support not methods" do
      @bloomfilter.should respond_to(:not_include?)
      @bloomfilter.should respond_to(:not_visited_url?)
      @bloomfilter.should respond_to(:not_touched_url?)
    end

    it "should store an array of urls in bloomfilter" do
      @bloomfilter.should respond_to(:visited_url?)

      @bloomfilter.visit_urls( ["http://a","http://b","http://c"] )
      ["http://a","http://b","http://c"].each do |url|
        @bloomfilter.touched_url?(url).should == true
      end

    end

    it "should detect normalized urls " do
      @bloomfilter.visit_url("https://www.google.com")
      @bloomfilter.visited_url?("http://www.google.com").should == true
    end

  end
end
