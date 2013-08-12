#!/usr/bin/env ruby
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
require 'rubygems'
require 'bundler/setup'
require 'trollop'

require 'socket'
require 'cloud-crawler'
require 'cloud-crawler/worker'


opts = Trollop::options do
  opt :queue_name, "name of crawl", :short => "-q",  :default => "crawls"  # must be same as start
  opt :worker_id, "id for this worker", :short => "-w", :default => Socket.gethostname
  
  opt :qless_host, "qless host", :short => "-h", :default => 'localhost'
  opt :qless_port, "qless port",  :short => "-p", :default => 6379
  opt :qless_db, "qless db", :short => "-B", :default => 0
  
  #opt :qless_queue, "", :short => "-q", :default => "crawl"   # :multi => true 

  # must be 1 or worker will break...also why we have batch jobs!
  opt :interval, "time delay interval", :short => "-i", :default => 1
  opt :job_reserver, "Ordered or RoundRobin", :short => "-r", :default => 'Ordered'
  opt :verbose, "verbos", :short => "-v", :default => true
  opt :single_process, "run as single process", :short => "-s", :default => false  
end

CloudCrawler::Worker.run(opts)


