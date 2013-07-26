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

    #MAX_BATCH_SIZE = 1000
    #MAX_HEARTBEAT = MAX_BATCH_SIZE*10


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
       LOGGER.info " process batch  #{jobs_batch.size}"
        
      next_jobs = jobs_batch.map do |hsh|
        LOGGER.info " process hash  #{hsh}"
        @job=hsh # hack for dsl
        hsh.symbolize_keys!
        sleep(delay) if delay
        process_job(hsh)
      end
      next_jobs.flatten!.compact!

      next_jobs.reject! { |j| j[:depth].to_i > depth_limit } if depth_limit
      return next_jobs
    end
    
    
    def self.do_save_batch!
      return unless save_batch?
      LOGGER.info " saving #{@s3_cache.keys.size} keys " 
      @s3_cache.s3.save! 
      LOGGER.info " num keys left #{@s3_cache.keys.size} "     
    end
    
    
    def self.perform(qjob)
      LOGGER.info "inside batch job #{qjob}"
      super(qjob)
      init(qjob)

      # use @ for DSL ... crappy design
      @data = qjob.data.symbolize_keys
      jobs = JSON.parse(data[:batch])
      LOGGER.info "performing #{jobs.size} batched jobs "

      while jobs.size > 0 do
        
        LOGGER.info " #{jobs.size} jobs being processed"
        
        jobs_batch = jobs.slice!(0,batch_size)
        
        LOGGER.info " #{jobs_batch.size} jobs_batch size"
        
        next_jobs = process_batch(jobs_batch)
        LOGGER.info "next jobs like #{next_jobs.first}"

        if queue_up? then
          LOGGER.info "queing up next jobs #{next_jobs.size}"
          next_jobs.each_slice(batch_size) do |batch|
            data[:batch] = batch.to_json
            @queue.put(self, data)
          end
        else #long_run
          LOGGER.info "running #{next_jobs.size}  next jobs on same worker"
          jobs << next_jobs
          jobs.flatten!.compact!
          
          # TODO:  save batch on every n jobs
          # this is a hack!!!
          do_save_batch!
        end

        
      LOGGER.info " #{jobs.size} jobs left"

      end #  while jobs.not_empty?
      
      # where are pages saved?
      
      do_save_batch!
      

    end
  end

end

