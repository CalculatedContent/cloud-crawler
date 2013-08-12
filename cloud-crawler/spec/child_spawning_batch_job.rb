#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content 
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#
require 'cloud-crawler/logger'
require 'cloud-crawler/batch_job'
require 'active_support/core_ext'

module CloudCrawler
  
  # bacth jobs will spawn
  
  class ChildSpawningBatchJob < BatchJob
    
    NUM_CHILDREN_SPAWNED = 22
    
    def self.process_batch(batch)
      m_cache.incr "num_batches"
      w_cache.incr "num_batches"
      super(batch)
    end

    # creates 3 sets of 3 new jobs
    def self.process_job(hsh)
     # puts "processing #{hsh}"
     
      w_cache.incr "num_jobs"
      m_cache.incr "num_jobs"
      
      m_cache["simple_job:#{hsh[:iid]}"]=hsh.to_json
      s3_cache["simple_job:#{hsh[:iid]}"]=hsh.to_json
      
      self.make_children(hsh)
    end

    # num nodes total (1..m).inject(0) { |s,i| s=s+n**i }
    #  for depth => num_children
    #   {1=>3, 2=>9, 3=>27}
    #  NOTE:  this does not quite work as expected
    #     batch of 10 => 220 jobs
    def self.make_children(hsh, n=3, m=3)
      children = []
      return children if hsh[:depth] >= m
      (0...n).to_a.map do |i|
        children << { :depth =>  hsh[:depth]+1, :prev => hsh, :iid=>rand(100_000_000) }
      end
      children << children.map{ |x| make_children(x, n, m) }
      return children.flatten
    end

  end

end


