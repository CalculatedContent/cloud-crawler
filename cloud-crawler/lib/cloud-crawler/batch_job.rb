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
  # expects bacth can create batches of subatched_jobs
  #  resubmits these jobs to the master queue, Or
  #  run the N jobs locally , in batch, syncing after every N steps
  # 
  #  currently only runs batch crawls...will eventually be broken up to run any job
  #
  class BatchJob
    include DslCore

    MAX_BATCH_SIZE = 1000
    MAX_HEARTBEAT = MAX_BATCH_SIZE*10


    #TODO: make sure this is thread and process safe
    #  make this a singleton ?
    # see perform()
    def self.init(qless_job)
            LOGGER.info "init batch   job"

      @namespace = @opts[:job_name]
      @queue_name = @opts[:queue_name]

      @m_cache = Redis::Namespace.new("#{@namespace}:m_cache", :redis =>  qless_job.client.redis)
      @m_cache.s3_init(@opts)

      @local_redis = Redis.new(:host=>'localhost')
      @w_cache = Redis::Namespace.new("#{@namespace}:w_cache", :redis =>  @local_redis)
      @s3_cache = Redis::Namespace.new("#{@namespace}:s3_cache", :redis =>  @local_redis)
      @s3_cache.s3_init(@opts)

      @queue = qless_job.client.queues[@queue_name]
      @batch_size = @opts[:batch_size] || MAX_BATCH_SIZE
      @depth_limit = @opts[:depth_limit]
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
    
    #TODO: implement
    def self.batch_id
      nil
    end

  
    
    # child class should implement
    def self.process_job(hsh)
      next_batch = []
      return next_batch
    end

    # start s3 pipeline?
    #  must be set in DSL..not important for now
    # if pipelined? then () else () end
    
    # this_batch = [{},{},{}]
    #   array of hashes
    def self.process_batch(this_batch)
       LOGGER.info " process batch  #{this_batch.size}"
       
      do_pre_batch 
      next_batch = this_batch.map do |hsh|
        LOGGER.info " process hash  #{hsh}"
        @job=hsh # hack for dsl
        hsh.symbolize_keys!
        sleep(delay) if delay
        process_job(hsh)
      end
      do_post_batch

      next_batch.flatten!.compact!

      next_batch.reject! { |j| j[:depth].to_i > depth_limit } if depth_limit
      return next_batch
    end
    
    #TODO:  make a post batch block and execute here
    def self.do_post_batch
      
      LOGGER.info " do post batch for #{batch_id}" 
      
      # execute post-batch block .. in dsl
       
      return unless save_batch?
      LOGGER.info " saving #{@s3_cache.keys.size} keys " 
      @s3_cache.s3.save! 
      
      LOGGER.info " num keys left #{@s3_cache.keys.size} "         
    end
    
    
    def self.do_pre_batch  
      LOGGER.info " do pre batch for #{batch_id}"
        
    end
    
    
    def self.perform(qless_job)
      LOGGER.info "inside qless batch job #{qless_job}"
      super(qless_job)
      init(qless_job)  # which does this call?  

      
      # use @ for DSL ... crappy design
      @data = qless_job.data.symbolize_keys
      batched_jobs = JSON.parse(data[:batch])
            
      LOGGER.info "performing #{batched_jobs.size} batched batched_jobs "
      while batched_jobs.size > 0 do
        
        LOGGER.info " #{batched_jobs.size} batched_jobs being processed"        
        this_batch = batched_jobs.slice!(0,batch_size)
        
        LOGGER.info " #{this_batch.size} this_batch size"      
        next_batch = process_batch(this_batch)
        
        LOGGER.info "next batched_jobs like #{next_batch.first}"

        if queue_up? then
          LOGGER.info "queing up next batched_jobs #{next_batch.size}"
          next_batch.each_slice(batch_size) do |batch|
            data[:batch] = batch.to_json
            @queue.put(self, data)
          end
        else #long_run
          LOGGER.info "running #{next_batch.size} next batched_jobs on same worker"
          batched_jobs << next_batch
          batched_jobs.flatten!.compact!

        end
        
      LOGGER.info " #{batched_jobs.size} batched_jobs left"

      end #  while jobs.not_empty      

    end
  end

end

