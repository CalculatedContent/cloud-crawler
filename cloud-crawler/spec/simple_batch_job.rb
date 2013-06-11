require 'cloud-crawler/logger'
require 'cloud-crawler/batch_job'
require 'simple_batch_job'
require 'active_support/core_ext'

module CloudCrawler
  class SimpleBatchJob < BatchJob
    


    def self.process_batch_with_counter(jobs_batch)
    #  puts "processing batch #{jobs_batch.size}"
      m_cache.incr "num_batches"
      w_cache.incr "num_batches"
         
      process_batch_without_counter(jobs_batch)
    end

    # did not work as hoped
    class << self
      alias_method_chain :process_batch, :counter
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

