require 'logger'

module CloudCrawler
  
  LOGGER =  Logger.new($stdout)
  LOGGER.formatter = Logger::Formatter.new
 
end
