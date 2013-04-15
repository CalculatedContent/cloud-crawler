require 'redis'
require 'json'
require 'bloomfilter-rb'

r = Redis.new
jobs = r.keys "*q*:j:*"

opts = {}
items, bits = 100_000, 5
      opts[:size] ||= items*bits
      opts[:hashes] ||= 7
      opts[:namespace] = "cc:pages_bf"
      opts[:db] = r
      
      # 2.5 mb? 
      bf = BloomFilter::Redis.new(opts)

puts bf

links = jobs.map do |j|
  JSON.parse(r.hget(j,"data"))["link"]
end

links[0...10].each do |l|
 # bf.insert l
  puts l 
  puts l if bf.include? l
end

puts links.size
puts links.compact.uniq.size




