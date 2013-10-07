#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content (TM)
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#
# All rights reserved.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL MADE BY MADE LTD BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
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
      LOGGER.info "init qless batch job"

      @namespace = @opts[:job_name]
      @queue_name = @opts[:queue_name]

      @qless_job = qless_job
      @m_cache = Redis::Namespace.new("#{@namespace}:m_cache", :redis =>  qless_job.client.redis)
      @m_cache.s3_init(@opts)

      @local_redis = Redis.new(:host=>'localhost')
      @w_cache = Redis::Namespace.new("#{@namespace}:w_cache", :redis =>  @local_redis)
      @s3_cache = Redis::Namespace.new("#{@namespace}:s3_cache", :redis =>  @local_redis)
      @s3_cache.s3_init(@opts)
      
    
      # cc master queue -- to augment qless features 
      @cc_master_q = Redis::Namespace.new("#{@namespace}:ccmq", :redis =>  qless_job.client.redis)

      # cc local queue -- local version that can cache info, like the dsl
      @cc_local_q = Redis::Namespace.new("#{@namespace}:cclq", :redis => @local_redis)
      
      # not to be accessed by dsl, hence the long name
      # notice this is local
      @cc_checkpoints = Redis::Namespace.new("#{@namespace}:cccp", :redis =>  @local_redis)
      @cc_checkpoints.s3_init(@opts)   
  

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
    
   
    
    # ccmq , cclq, and cccp are prviate
    # not sure how to make private from dsl?
    


    def self.checkpoint?
      @opts[:checkpoint]
    end
  
    # 
    def self.qjob_limit?
      @opts[:job_limit] # true if not nill
    end
  
    def self.max_qjobs
      (@opts[:job_limit] || -1).to_i
    end
    

    # should be memory size
    # need to flush queue, remove or serialize jobs
    def self.num_jobs_on_qless
       @qless_job.client.redis.keys("ql:j:*").size
    end
    
    # same as crawl job
    def self.get_blocks(id)
      json = @cc_master_q["dsl_blocks:#{id}"]
      if json then JSON.parse(json) else {} end
    end
    
    
    
    # child class should implement
    def self.process_job(hsh)
      next_batch = []
      return next_batch
    end

    #  must be set in DSL..not important for now
    # if pipelined? then () else () end
    
    # this_batch = [{},{},{}]
    #   array of hashes
    def self.process_batch(this_batch)
      LOGGER.info " processing batch of size #{this_batch.size}"
       
      setup_dsl(dsl_id)
      do_pre_batch 
      next_batch = this_batch.map do |hsh|
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
       
      if save_batch? then
        @s3_cache.s3.save!   
        LOGGER.info " num keys left #{@s3_cache.keys.size} "         
      end

      if checkpoint? then
        num_checkpoints = @cc_checkpoints.keys("*").size
        if num_checkpoints > 0
          LOGGER.info " checkpointing #{num_checkpoints} jobs "  
          @cc_checkpoints.s3.save!  if save_batch?  
        end
      end
      
    end
    
    
    
    def self.do_pre_batch  
      LOGGER.info " do pre batch for #{batch_id}"
        
      # is this the root job?
      #  driver marks the job
      if @data[:first_job] then
        do_before_crawl
      end
      
    end
    
    # http://redis.io/commands/info
    #  can also monitor redis memory
    def self.submit_qless_job(data)
      LOGGER.info "submit_qless_job  # jobs #{num_jobs_on_qless} ,  max_qjobs > #{max_qjobs}"
      if qjob_limit? and num_jobs_on_qless >= max_qjobs
         LOGGER.info "too many jobs ...  not submitting "
         checkpoint(data) if checkpoint?
         # TODO: issue a save if local redis is running out of memory
         # TODO: consider placing all jobs in checkpoint queue first, saving, and then submitting?
         # TODO:  optimize DSL -- get the damn queue smaller
         # TODO: implement ASAP on AWS Elastic Redis also
      else
        @queue.put(self, data)
      end
    end
    
    # save the job for graceful (or less graceful) restart
    #  push to s3-cache, but s3_cache might crash
    #  => s3_cache needs buffer overflow capacity also
    def self.checkpoint(data)
      LOGGER.info "checkpointing"
      
      # code = data.hash  # a hash code : this never works
      
      # auto increment key for checkpointed data blocks
      bid = @cc_checkpoints.incr("bid")  # a number starting at 1
      
      # probably should be 
      #   bid = data[:batch_id]
     
      key = "batch:#{bid}"
      
      # must be a valid hash that can be parsed
      @cc_checkpoints[key] = { :batch => JSON.parse(data[:batch]) }.to_json 
      num_cps = @cc_checkpoints.keys("batch:*")
      LOGGER.info  "num checkpoints = #{num_cps}"
    
      puts "check point data #{key}  #{@cc_checkpoints[key]}"
      # if save/_batch
      # this gets save at the end of the batch?
      # if s3 cache runs out of memory, we are fucked
    end
    
    
    # qless_job is a batch of jobs to perform locally or resubmit
    def self.perform(qless_job)
      super(qless_job)
      init(qless_job)  # which does this call?  

      LOGGER.info "performing qless batch job, id = #{batch_id}"

      # use @ for DSL ... crappy design
      #  create in init:  @data = qless_job.data.symbolize_keys
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
            data[:first_job] = false
            # increment job id somehow?
            
            success = submit_qless_job(data)
        
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

