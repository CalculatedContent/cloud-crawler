require 'rubygems'
require 'bundler/setup'
require 'fakeweb'
require File.dirname(__FILE__) + '/fakeweb_helper'

$:.unshift(File.dirname(__FILE__) + '/../lib/')
require 'cloud_crawler'

SPEC_DOMAIN = 'http://www.example.com/'
