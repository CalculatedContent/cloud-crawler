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
require 'robotex'
require 'sourcify'
require 'json'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'cloud-crawler/logger'

module CloudCrawler

 #TODO:  these are never actually input
 #  need to reconcile with unit tests and trollop
  DEFAULT_OPTS = {
    # disable verbose output
    :verbose => false,
    #  throw away the page response body after scanning it for links
    :discard_page_bodies => false,
    # identify self as CloudCrawler
    :user_agent => "CloudCrawler",
    # no delay between requests
    :delay => 0,
    # don't obey the robots exclusion protocol
    :obey_robots_txt => false,
    # by default, don't limit the depth of the crawl
    :depth_limit => false,
    # number of times HTTP redirects will be followed
    :redirect_limit => 5,
    # Hash of cookie name => value to send with HTTP requests
    :cookies => nil,
    # accept cookies from the server and send them back?
    :accept_cookies => false,
    # skip any link with a query string? e.g. http://foo.com/?u=user
    :skip_query_strings => false,
    # proxy server hostname
    :proxy_host => nil,
    # proxy server port number
    :proxy_port => false,
    # HTTP read timeout in seconds
    :read_timeout => nil,
    
    # allow links outside of the root domain
    :outside_domain => false,
    # allow links inside of the root domain
    :inside_domain => true,
    
    # save batch jobs in s3
    :save_batch => true
  
  }

  # does DSL can use instance methods or class instance methods ?
  module DslFrontEnd
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods

      # where are the getters?
      DEFAULT_OPTS.keys.each do |key|
        define_method "#{key}=" do |value|
          @opts[key.to_sym] = value
        end
      end

      def init(opts={}, &block)
        @opts = opts.reverse_merge! DEFAULT_OPTS

        @focus_crawl_block = nil
        @on_every_page_blocks = []
        @skip_link_patterns = []
        #  @after_crawl_blocks = []
        @on_pages_like_blocks = Hash.new { |hash,key| hash[key] = [] }

        yield self if block_given?
      end
      
      def opts
        @opts
      end

      def block_sources
        blocks = {}
        blocks[:focus_crawl_block] = [@focus_crawl_block].compact.map(&:to_source).to_json
        blocks[:on_every_page_blocks] = @on_every_page_blocks.compact.map(&:to_source).to_json
        blocks[:skip_link_patterns] = @skip_link_patterns.compact.to_json
        blocks[:on_pages_like_blocks] = @on_pages_like_blocks.each{ |_,a|  a.compact.map!(&:to_source) }.to_json
        return blocks
      end

      #TODO:  implement later in driver
      #
      # def after_crawl(&block)
      # @after_crawl_blocks << block
      # self
      # end

      #
      # Add one ore more Regex patterns for URLs which should not be
      # followed
      #
      def skip_links_like(*patterns)
        @skip_link_patterns.concat [patterns].flatten.compact.map { |x| x.source }
        self
      end

      #
      # Add a block to be executed on every Page as they are encountered
      # during the crawl
      #
      def on_every_page(&block)
        @on_every_page_blocks << block
        self
      end

      #
      # Add a block to be executed on Page objects with a URL matching
      # one or more patterns
      #
      def on_pages_like(*patterns, &block)
        if patterns
          patterns.each do |pattern|
            @on_pages_like_blocks[pattern.source] << block
          end
        end
        self
      end

      #
      # Specify a block which will select which links to follow on each page.
      # The block should return an Array of URI objects.
      #
      def focus_crawl(&block)
        @focus_crawl_block = block
        self
      end

    end
  end

end
