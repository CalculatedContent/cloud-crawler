$:.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'child_spawning_batch_job'

module CloudCrawler
  describe ChildSpawningBatchJob do

    it "should create the correct number of child jobs" do

      m, n = 3, 3
      num = (1..m).inject(0) { |s,i| s=s+n**i }

      children = ChildSpawningBatchJob.make_children({:depth=>0})
      children.size.should == num

    end

    it "should create hashes with depth <= 3 and prev hsh linked in" do
    
      depth = 3
      
      children = ChildSpawningBatchJob.make_children({:depth=>0})
      children.each do |hsh|
        hsh[:depth].should be <= depth
        hsh[:prev].should_not be_nil
      end

    end

  end

end
