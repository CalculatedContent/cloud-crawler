#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content 
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#
$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'cloud-crawler/driver'

describe CloudCrawler do

  it "should have a version" do
    CloudCrawler.const_defined?('VERSION').should == true
  end

  it "should return a CloudCrawler::Driver from the crawl" do
    result = CloudCrawler.crawl(SPEC_DOMAIN)
    result.should be_an_instance_of(CloudCrawler::Driver)
  end

end
