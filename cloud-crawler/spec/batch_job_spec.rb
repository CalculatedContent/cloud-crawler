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
$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'redis'
require 'cloud-crawler/batch_job'
require 'cloud-crawler/driver'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'child_spawning_batch_job'
require 'make_test_blocks'

require 'qless'
require 'sourcify'

module CloudCrawler
  include MakeTestBlocks
  describe BatchJob do

    before(:each) do
      FakeWeb.clean_registry
      @redis = Redis.new
      @redis.flushall

      @opts = {}
      @opts.reverse_merge! CloudCrawler::Driver::DRIVER_OPTS
      @opts.reverse_merge! CloudCrawler::DEFAULT_OPTS
    
      @opts[:queue_name] = 'test_batch_job_spec'
      @opts[:depth_limit] = 2 # => gives 60 jobs
      @opts[:save_batch] = false   # deal with permissions later
      @opts[:batch_size] = 10
      
      @client = Qless::Client.new()
      
      @queue = @client.queues[@opts[:queue_name]]

      @namespace = @opts[:job_name] || 'simple_batch_job'
      @m_cache = Redis::Namespace.new("#{@namespace}:m_cache", :redis => @redis)
      @w_cache = Redis::Namespace.new("#{@namespace}:w_cache", :redis => @redis)
      @s3_cache = Redis::Namespace.new("#{@namespace}:s3_cache", :redis => @redis)
      
      @cc_checkpoints = Redis::Namespace.new("#{@namespace}:cccp", :redis =>  @local_redis)

      # cc master queue
      @cc_master_q = Redis::Namespace.new("#{@namespace}:ccmq", :redis =>  @client.redis)
 
    end

    after(:each) do
      @redis.flushdb
    end

   
    
    def run_batch(batch)
      data = {}
      data[:opts] = @opts.to_json
      data[:batch] = batch.to_json
      data[:dsl_id] = MakeTestBlocks::make_test_blocks(@cc_master_q, {})
   
      @queue.put( CloudCrawler::ChildSpawningBatchJob, data )

      num_ran_batch_jobs = 0
      while qjob = @queue.pop
        @queue.pop
         qjob.perform
         num_ran_batch_jobs += 1
      end

      return num_ran_batch_jobs

    end

    # can I just specific as SimpleBatchJob

    # batch_job.should respond_to(:queue_up?)
    # batch_job.should respond_to(:long_run?)
    # batch_job.should respond_to(:depth_limit)
    # batch_job.should respond_to(:batch_size)

    # process_job

    # batch_job.should respond_to(:m_cache)
    # batch_job.should respond_to(:w_cache)
    # batch_job.should respond_to(:s3_cache)

    def make_batch  
      batch = (0...@opts[:batch_size]).to_a.map do |i|
        { :depth=> 0 }
      end
 
      return batch
    end
    
    
    it "should break jobs into batches and run in chunks locally, by default" do
      puts "....\n\n"

      num_ran_batch_jobs = run_batch(make_batch)
      num_ran_batch_jobs.should == 1
      
      @m_cache['num_jobs'].to_i.should == @opts[:batch_size]*ChildSpawningBatchJob::NUM_CHILDREN_SPAWNED
      @m_cache['num_batches'].to_i.should ==   @m_cache['num_jobs'].to_i / @opts[:batch_size]

    end

    it "should create new jobs and place them on the queue" do
      puts "....\n\n"
      @opts[:queue_up] = true

      num_ran_batch_jobs = run_batch(make_batch)
      puts num_ran_batch_jobs
      num_ran_batch_jobs.should == 10 # hard coded for now
    end
  
    it "should stop if the depth limit is reached" do   
      puts "....\n\n"
      @opts[:depth_limit] = 1
      num_ran_batch_jobs = run_batch(make_batch)
      
      # check depth limit
      keys = @m_cache.keys "simple_job:*"
      keys.each do |k|
         hsh = JSON.parse(@m_cache[k])
         hsh["depth"].to_i.should be <= @opts[:depth_limit]
      end
      
      # check depth limit
      @opts[:depth_limit] = 4
      num_ran_batch_jobs = run_batch(make_batch)
      keys = @m_cache.keys "simple_job:*"
      keys.each do |k|
         hsh = JSON.parse(@m_cache[k])
         hsh["depth"].to_i.should be <= @opts[:depth_limit]
      end
      
      
    end
   
    
    
       
    it 'should not resubmit any jobs since queue_up is false ' do
      puts "....\n\n"
      JOB_LIMIT = 10
      @opts[:checkpoint] = false # default is true
      @opts[:job_limit] = JOB_LIMIT    
      @opts[:queue_up] = false #default is false, but we dont rely on defaults 
             
      JOB_LIMIT.times do |i|
         num_ran_batch_jobs = run_batch(make_batch) 
         num_ran_batch_jobs.should == 1
        
         num_qjobs =  @redis.keys("ql:j:*").size  # keys returns an array          
         num_qjobs.should == i+1
      end
  
  
      # a batch of 10 child spawning batch jobs creates (10*22=220) child crawl jobs
      num_crawl_jobs =  @m_cache["num_jobs"].to_i
      num_crawl_jobs.should == JOB_LIMIT*@opts[:batch_size]*ChildSpawningBatchJob::NUM_CHILDREN_SPAWNED
    end
    
     # this test only works if queue_up is true
    # if queue_up is false, then the jobs keep going
    it "should NOT stop at the  max number of jobs since queue_up is false" do   
      JOB_LIMIT = 10
      @opts[:checkpoint] = false # default is true
      @opts[:job_limit] = JOB_LIMIT   
      @opts[:queue_up] = false
      
      num_ran_batch_jobs = run_batch(make_batch) 
      num_ran_batch_jobs.should == 1
      
      num_qjobs =  @redis.keys("ql:j:*").size  # keys returns an array
      num_qjobs.should == 1

       
      # a batch of 10 child spawning batch jobs creates (10*22=220) child crawl jobs
      num_crawl_jobs = @m_cache["num_jobs"].to_i
      num_crawl_jobs.should == @opts[:batch_size]*ChildSpawningBatchJob::NUM_CHILDREN_SPAWNED
    end
    
    
    it "should stop max number of jobs since queue_up is true" do   
     puts "....\n\n"
      JOB_LIMIT = 10
      @opts[:checkpoint] = false # default is true
      @opts[:job_limit] = JOB_LIMIT   # batch job limit or crawl job limit
      @opts[:queue_up] = true
      
      # each child spawn job will spawn many jobs
      # so the total number of jobs run here could be < 10
      num_ran_batch_jobs = run_batch(make_batch)     
      num_ran_batch_jobs.should be < JOB_LIMIT
     
      # but the total number qless jobs on redis should == 10
      num_qjobs =  @redis.keys("ql:j:*").size  # keys returns an array
      num_qjobs.should == JOB_LIMIT
      
      num_crawl_jobs = @m_cache["num_jobs"].to_i       
    end
    
    
    
     # this needs to be mocked to s3
      it "should put the extra jobs in a data key in the checkpopint cache" do   
       @opts[:checkpoint] = true # will save the resubmitted jobs to s3 instead of redis
       @opts[:save_batch] = false  # save_batch also saves the  batch checkpoint

       @opts[:job_limit] = JOB_LIMIT   # batch job limit or crawl job limit
       @opts[:queue_up] = true
      
      # --- SAME AS ABOVE ---
      # each child spawn job will spawn many jobs
      # so the total number of jobs run here could be < 10
      num_ran_batch_jobs = run_batch(make_batch)     
      num_ran_batch_jobs.should be < JOB_LIMIT
     
      # but the total number qless jobs on redis should == 10
      num_qjobs =  @redis.keys("ql:j:*").size  # keys returns an array
      num_qjobs.should == JOB_LIMIT
      
      num_crawl_jobs = @m_cache["num_jobs"].to_i             

      #  --- --- --- --- ---


      cp_keys = @cc_checkpoints.keys("batch:*")
      cp_keys.should_not be_nil
      
      cp_keys.size.should be > 1
            
      batch_json = @cc_checkpoints["batch:1"]  # the actual batch data
      batch_array = JSON.parse(batch_json)
      batch_array.should be_kind_of Hash
      batch_array.should_not be_empty
      
  
    end

  # testing requirs mocks / acceess to s3
  # non-trivial...I will try to set up
  # need to checkpoint, flush the jobs only, and then resubmit upto a limit
  # jobs should be checkpointed to s3 and then pulled back, => a good naming scheme
  # large number of jobs => use redis hashes, not sets?
  it 'should support a graceful restart' do
    
  end
  
  #TODO: optimize so jobs can be restarted without flushing / storing the entire DSL
  #  a major refector that will take time to develop
  # TODO:  test on amazon elsatic cache
  # TODO: test just jobs on amazon...maybe batch is not necessary for elastic cache?
      
    
  it "should have access to the master cache" do
      puts "....\n\n"
      run_batch(make_batch)
      
      keys = @m_cache.keys("*")
      keys.should_not be_empty
  end
  
  it "should have access to the worker cache" do
      puts "....\n\n"
      run_batch(make_batch)
      
      keys = @w_cache.keys("*")
      keys.should_not be_empty
  end
  
  it "should have access to the s3cache cache" do
      puts "....\n\n"
      run_batch(make_batch)
      
      keys = @s3_cache.keys("*")
      keys.should_not be_empty
  end
  
#   
  # it 'should optionally turn off the s3 cache save' do
    # # not tested here...until s3 is mocked up
  # end
#   
#   
  # it 'should include montioring for batch processing in the local and master queues' do
  # end
#   
  # it 'should support some sane logging' do
#     
  # end
#   
  # it ' should allow a child class to access @job through the dsl' do
#     
  # end
  
 # TODO:   implement this test
    it 'should have a batch_id ' do
      
    end
    
    it 'should have fail if the batch_id is not set on submission ' do
      
    end
    
    
     it 'should not look up the dsl if the dsl_id is nil ' do
      
     end
     
      it 'should not fail if the job_id is not set ' do
      
     end
     
     it 'should stop if the dsl_id is invalid ' do
      
     end
     
     
    
    
     # TODO:   implement this test
    it 'should have (at least private) access to the cc_master_q' do
      
    end


  # TODO:   implement this test
    it 'should have (at least private) access to the local checkpoint queue' do
      
    end
    
    

  end
end

#TODO:  figure out how to test the checkponts
# Im ok to use S3 directly