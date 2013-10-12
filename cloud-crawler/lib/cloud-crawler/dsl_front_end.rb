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
require 'active_support/inflector'
require 'active_support/core_ext'
require 'cloud-crawler/logger'
require 'cloud-crawler/dsl_common'

module CloudCrawler

  #TODO:  these are never actually input
  #  need to reconcile with unit tests and trollop
  DEFAULT_OPTS = {
    # disable verbose output
    :verbose => false,
    #  throw away the page response body after scanning it for links
    :discard_page => false,
    # identify self as CloudCrawler
    :user_agent => "CloudCrawler",
    # no delay between requests
    :delay => 0,
    # do obey the robots exclusion protocol by default
    :obey_robots_txt => true,
    # by default, don't limit the depth of the crawl
    :depth_limit => false,
    # number of times HTTP redirects will be followed
    :redirect_limit => 5,
    # keep all pages , even redirects
    :keep_redirects => true,
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
    :save_batch => true,

    # auto-increment batch and job ids if they are nil
    :auto_increment => true,

    # limit number of jobs on queue to prevent buffer overflow
    :job_limit => 10_000,

    # checkpoint turned on, only used for now when job limit is specified
    :checkpoint => true

  }

  # does DSL can use instance methods or class instance methods ?
  module DslFrontEnd
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      include DslCommon

      # where are the getters?
      DEFAULT_OPTS.keys.each do |key|
        define_method "#{key}=" do |value|
          @opts[key.to_sym] = value
        end
      end

      def init(opts={}, &block)
        @opts = opts.reverse_merge! DEFAULT_OPTS

        @focus_crawl_block = nil
        @on_every_page_block = nil

        @after_crawl_block = nil
        @before_crawl_block = nil

        @after_batch_block = nil
        @before_batch_block = nil

        @skip_link_patterns = []
        @on_pages_like_blocks = Hash.new { |hash,key| hash[key] = [] }

        yield self if block_given?
      end

      def opts
        @opts
      end

      
      def make_opts
        compress opts
      end

      # driver provides callback into cache
      def make_blocks
        data  = compress block_sources
        id = put_blocks_in_cache(data) # would prefer qless id here if possible
        return id
      end
      
      def make_batch(batch=[])
        compress batch
      end

      def block_sources
        blocks = {}
        blocks[:focus_crawl_block] = block_to_source @focus_crawl_block
        blocks[:on_every_page_block] = block_to_source @on_every_page_block
        blocks[:on_after_crawl_block] = block_to_source @after_crawl_block
        blocks[:on_before_crawl_block] = block_to_source @before_crawl_block
        blocks[:on_after_batch_block] = block_to_source @after_batch_block
        blocks[:on_before_batch_block] = block_to_source @before_batch_block

        blocks[:skip_link_patterns] = @skip_link_patterns.compact
        blocks[:on_pages_like_blocks] = @on_pages_like_blocks.each{ |_,a|  a.compact.map!(&:to_source) }
        return blocks
      end

      def block_to_source(block)
        if block then block.to_source else nil end
      end

      # TODO:  replacen with MP
      def after_crawl(&block)
        @after_crawl_block = block
        self
      end

      def before_crawl(&block)
        @before_crawl_block = block
        self
      end

      def after_batch(&block)
        @after_batch_block = block
        self
      end

      def before_batch(&block)
        @before_batch_block = block
        self
      end

      #
      # Add a block to be executed on every Page as they are encountered
      # during the crawl
      #
      def on_every_page(&block)
        @on_every_page_block = block
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
        "making focus crawl block #{block}"
        @focus_crawl_block = block
        self
      end

      #
      # Add one ore more Regex patterns for URLs which should not be
      # followed
      #
      def skip_links_like(*patterns)
        @skip_link_patterns.concat [patterns].flatten.compact.map { |x| x.source }
        self
      end

    end
  end

end
