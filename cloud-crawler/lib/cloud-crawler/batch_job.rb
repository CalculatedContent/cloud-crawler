require 'cloud-crawler/logger'
require 'cloud-crawler/http'
require 'cloud-crawler/redis_page_store'
require 'cloud-crawler/redis_url_bloomfilter'
require 'cloud-crawler/dsl_core'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'redis-caches/s3_cache'

module CloudCrawler
  
  # 
  # Process a batch of N jobs
  #  Provides access to the local and master caches, and s3 cache
  #
  # syncs s3 cache after every slice
  # expects bacth can create batches of subjobs
  #  resubmits these jobs to the master queue, Or
  #  run the N jobs locally , in batch, syncing after every N steps
  # 
  #  currently only runs batch crawls...will eventually be broken up to run any job
  #
  class BatchJob
    include DslCore

    MAX_BATCH_SIZE = 1000

    #TODO: make sure this is thread and process safe
    #  make this a singleton ?
    # see perform()
    def self.init(qjob)
      @namespace = @opts[:job_name]
      @queue_name = @opts[:queue_name]

      @m_cache = Redis::Namespace.new("#{@namespace}:m_cache", :redis =>  qjob.client.redis)
      @m_cache.s3_init(@opts)

      @local_redis = Redis.new(:host=>'localhost')
      @w_cache = Redis::Namespace.new("#{@namespace}:w_cache", :redis =>  @local_redis)
      @s3_cache = Redis::Namespace.new("#{@namespace}:s3_cache", :redis =>  @local_redis)
      @s3_cache.s3_init(@opts)

      @queue = qjob.client.queues[@queue_name]
      @batch_size = @opts[:batch_size] || MAX_BATCH_SIZE
      @depth_limit = @opts[:depth_limit]
    end

    def self.init_job
     
    end
    
    def self.save_batch?
       @opts[:save_batch]
    end

    def self.queue_up?
      @opts[:queue_up]
    end

    def self.long_run?
      @opts[:queue_up].nil? ||  @opts[:queue_up].false?
    end

  
    def self.depth_limit
      @depth_limit
    end

    def self.batch_size
      @batch_size
    end

    def self.m_cache
      @m_cache
    end

    def self.w_cache
      @w_cache
    end

    # write only cache
    def self.s3_cache
      @s3_cache
    end

    # child class should implement
    def self.process_job(hsh)
      next_jobs = []
      return next_jobs
    end

    # start s3 pipeline?
    #  must be set in DSL..not important for now
    # if pipelined? then () else () end
    
    def self.process_batch(jobs_batch)
      next_jobs = jobs_batch.map do |hsh|
        hsh.symbolize_keys!
        sleep(delay) if delay
        process_job(hsh)
      end
      next_jobs.flatten!.compact!

      next_jobs.reject! { |j| j[:depth].to_i >= depth_limit } if depth_limit
      return next_jobs
    end
    
    

    def self.perform(qjob)
      super(qjob)
      init(qjob)

      data = qjob.data.symbolize_keys
      jobs = JSON.parse(data[:batch])

      while jobs.size > 0 do
        
        jobs_batch = jobs.slice!(0,batch_size)
        next_jobs = process_batch(jobs_batch)

        if queue_up? then
          next_jobs.each_slice(batch_size) do |batch|
            data[:batch] = batch.to_json
            @queue.put(self, data)
          end
        else #long_run
          jobs << next_jobs
          jobs.flatten!.compact!
        end

        @s3_cache.s3.save! if save_batch? # for debugging

      end #  while jobs.not_empty?

    end
  end

end

