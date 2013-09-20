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
require 'rubygems'
require 'bundler/setup'
require 'qless'
require 'json'
require 'active_support/core_ext'
require 'make_test_blocks'


module CloudCrawler
  class TestBatchCrawlJob 
    include MakeTestBlocks
    
    attr_accessor :data, :client, :queue
    def initialize(links, opts, ccmq, blocks)
      @client = Qless::Client.new
      @queue_name = opts[:queue_name] 
      @queue = @client.queues[@queue_name]
      
      @data = {}
      @data[:opts] = opts.to_json     
      @data[:dsl_id] = make_test_blocks(ccmq, blocks)
         
      @data[:batch] = [links].flatten.map { |lnk|  { :link =>  lnk, :depth => 0 } }.to_json
    end
    

  end

end