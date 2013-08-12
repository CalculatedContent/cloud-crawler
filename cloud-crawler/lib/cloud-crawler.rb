#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content 
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#
require 'rubygems'
require 'bundler/setup'
require 'cloud-crawler'
require 'cloud-crawler/logger'
require 'cloud-crawler/cookie_store'
require 'cloud-crawler/http'
require 'cloud-crawler/page'
require 'cloud-crawler/redis_page_store'
require 'cloud-crawler/driver'
require 'cloud-crawler/dsl_core'
require 'cloud-crawler/dsl_front_end'
require 'cloud-crawler/crawl_job'
require 'cloud-crawler/batch_crawl_job'
require 'cloud-crawler/batch_curl_job'
require 'cloud-crawler/worker'

