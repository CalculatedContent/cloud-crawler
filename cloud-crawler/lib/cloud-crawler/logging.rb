require 'logger'

#TODO:  emulate rails logging
module CloudCrawler
  class Error < ::StandardError
    attr_accessor :wrapped_exception
  end
  
  @logger = Logger.new(STDERR)
  
  def logger
    @logger
  end  
  
end
