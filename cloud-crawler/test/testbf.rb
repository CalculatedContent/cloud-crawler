#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content 
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#
require 'redis'
require 'bloomfilter-rb'

bf = BloomFilter::Redis.new( {:seed=>1364249661})

puts bf.inspect

#bf.insert :hello
bf.insert :world

puts bf.include? :hello
puts bf.include? :world


