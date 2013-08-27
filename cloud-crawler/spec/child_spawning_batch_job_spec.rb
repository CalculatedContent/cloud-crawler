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
