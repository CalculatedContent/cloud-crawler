require 'robotex'
require 'sourcify'
require 'json'
require 'active_support/inflector'
require 'active_support/core_ext'


module CloudCrawler

  module DslCore
    def self.included(base)
      base.send :extend, ClassMethods
     # base.send :extend, InstanceMethods
    end

    module ClassMethods
      # Qless hook
      def perform(job)
        @data = job.data.symbolize_keys
        @opts = JSON.parse(data[:opts]).symbolize_keys
        @robots = Robotex.new(@opts[:user_agent]) if @opts[:obey_robots_txt]

        @focus_crawl_block = JSON.parse(data[:focus_crawl_block]).first
        @on_every_page_blocks = JSON.parse(data[:on_every_page_blocks])
        @on_pages_like_blocks = JSON.parse(data[:on_pages_like_blocks])
        @skip_link_patterns = JSON.parse(data[:skip_link_patterns])        
      # for performance, should construct REGEXPs here, not with /#{pattern}/
      #  @after_crawl_blocks = JSON.parse(data[:after_crawl_blocks])
      end

     def data
       @data
     end
    
 
     def opts
       @opts
     end
     
     def delay
       @opts[:delay]
     end
     
     def worker_id
       @opts[:worker_id]
     end
    
      #
      # TODO: implement locally
      #
      def do_after_crawl_blocks
        @after_crawl_blocks.each { |block| instance_eval(block).call(@page_store) }
      end

      #
      # Execute the on_every_page blocks for *page*
      #
      def do_page_blocks(page)
        @on_every_page_blocks.each do |block|
          instance_eval(block).call(page)
        end

        @on_pages_like_blocks.each do |pattern, blocks|
          blocks.each { |block| instance_eval(block).call(page) } if page.url.to_s =~ /#{pattern}/
        end
      end

      #
      # Return an Array of links to follow from the given page.
      # Based on whether or not the link has already been crawled,
      # and the block given to focus_crawl()
      #
      def links_to_follow(page)
        @page = page  # need below, sorry
        links = @focus_crawl_block ? instance_eval(@focus_crawl_block).call(page) : page.links
        links.select { |link| visit_link?(link, page) }.map { |link| link.dup }
      end
      
      def text_for(link)
        @page.text_for(link)
      end
      
      def dom_for(link)
        @page.dom_for(link)
      end
      

      #
      # Returns +true+ if *link* has not been visited already,
      # and is not excluded by a skip_link pattern...
      # and is not excluded by robots.txt...
      # and is not deeper than the depth limit
      # Returns +false+ otherwise.
      #
      def visit_link?(link, from_page = nil)
        !@bloomfilter.visited_url?(link) &&
        !skip_link?(link) &&
        !skip_query_string?(link) &&
        allowed(link) &&
        in_domain?(link, from_page) &&
        !too_deep?(from_page)
      end

      #
      # Returns +true+ if we are obeying robots.txt and the link
      # is granted access in it. Always returns +true+ when we are
      # not obeying robots.txt.
      #
      def allowed(link)
        @opts[:obey_robots_txt] ? @robots.allowed?(link) : true
      rescue
        false
        end

      #
      # optionally allows outside_domain links
      #
      def in_domain?(link, from_page)
        if from_page.in_domain? link then
          @opts[:inside_domain]
        else
          @opts[:outside_domain]
        end
      end
      #
      # Returns +true+ if we are over the page depth limit.
      # This only works when coming from a page and with the +depth_limit+ option set.
      # When neither is the case, will always return +false+.
      def too_deep?(from_page)
        if from_page && @opts[:depth_limit]
          from_page.depth >= @opts[:depth_limit]
        else
          false
        end
      end

      #
      # Returns +true+ if *link* should not be visited because
      # it has a query string and +skip_query_strings+ is true.
      #
      def skip_query_string?(link)
        @opts[:skip_query_strings] && link.query
      end

      #
      # Returns +true+ if *link* should not be visited because
      # its URL matches a skip_link pattern.
      #
      def skip_link?(link)
        @skip_link_patterns.any? { |pattern| link.path =~ /#{pattern}/  }
      end

    end
  end
end
