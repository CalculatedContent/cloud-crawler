require 'logger'

#TODO:  emulate rails logging
module CloudCrawler
  @logger = Logger.new(STDERR)
  
  def logger
    @logger
  end  
  
end
