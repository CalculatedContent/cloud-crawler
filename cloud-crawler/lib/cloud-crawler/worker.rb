#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content (TN)
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
require 'qless'
require 'qless/worker'

module CloudCrawler
  class Worker
    
    def self.run(opts={})      
      
      ENV['REDIS_URL']= "redis://#{opts[:qless_host]}:#{opts[:qless_port]}/#{opts[:qless_db]}"
      ENV['QUEUES'] = opts[:queue_name]
      
      ENV['JOB_RESERVER'] = opts[:job_reserver]
      ENV['INTERVAL'] = opts[:interval].to_s
      ENV['VERBOSE'] = opts[:verbose].to_s
      ENV['RUN_AS_SINGLE_PROCESS'] = opts[:single_process].to_s

      Qless::Worker::start
    end
    
  end  
end


