require 'logger'

#TODO:  emulate rails logging

# does not seem to load

module CloudCrawler
  @logger = Logger.new(STDERR)
  
  def logger
    @logger
  end  
  
end
