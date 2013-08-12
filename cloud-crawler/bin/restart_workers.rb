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
require 'fog'
require 'socket'
require 'logger'

cc_dir = "/home/ubuntu/cc/cloud-crawler"
log_dir = "#{cc_dir}/logs"

log = Logger.new("#{log_dir}/master.log")

#TODO:  read from .s3cfg, hard code region

aws_access_key_id = `grep access_key /home/ubuntu/.s3cfg | awk '{print $3}'`.chomp
aws_secret_access_key = `grep secret_key /home/ubuntu/.s3cfg | awk '{print $3}'`.chomp
aws_region = 'us-west-1' #ENV['EC2_REGION']

c = Fog::Compute.new(
:provider => 'AWS',
:aws_access_key_id => aws_access_key_id,
:aws_secret_access_key => aws_secret_access_key,
:region => aws_region )

log.error 'restart-workers: can not connect' if c.nil?

stopped_workers = c.servers.select { |s| s.state=='stopped' }

log.info "restart-workers: found #{stopped_workers.size} stopped_workers"
stopped_workers.each do |w|
  log.info "restart-workers: starting worker #{w.to_s}"
  w.start
end
