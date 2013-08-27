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


