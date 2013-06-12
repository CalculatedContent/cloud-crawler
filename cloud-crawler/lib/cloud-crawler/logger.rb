require 'logger'

#TODO:  emulate rails logging

# does not seem to load

module CloudCrawler
  
  LOGGER = Logger.new($stdout)
  
  def logger
    LOGGER
  end 
  
   def self.logger
    LOGGER
  end  
  
end
