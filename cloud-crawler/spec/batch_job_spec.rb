$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'redis'
require 'cloud-crawler/batch_job'
require 'cloud-crawler/driver'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'child_spawning_batch_job'
require 'qless'
require 'sourcify'

module CloudCrawler
  describe BatchJob do

    before(:each) do
      FakeWeb.clean_registry
      @redis = Redis.new
      @redis.flushall

      @opts = CloudCrawler::Driver::DRIVER_OPTS
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

    end

    after(:each) do
      @redis.flushdb
    end

    def run_batch(batch)
      data = {}
      data[:opts] = @opts.to_json
      data[:batch] = batch.to_json
            
      # because we need to break dsl core out of of batch job eventually
      data[:focus_crawl_block] = [].to_json
      data[:on_every_page_blocks] = [].to_json
      data[:skip_link_patterns] =  [].to_json
      data[:on_pages_like_blocks] = Hash.new { |hash,key| hash[key] = [] }.to_json

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


  end
end