module CloudCrawler
  class Error < ::StandardError
    attr_accessor :wrapped_exception
  end
end
