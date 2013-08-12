#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content 
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#
require 'cloud-crawler/logger'
module CloudCrawler
  class Error < ::StandardError
    attr_accessor :wrapped_exception
  end
end
