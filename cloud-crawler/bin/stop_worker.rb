
#!/usr/bin/env ruby

# Copyright (c) 2013, Calculated Content (TM)
# All rights reserved.

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

cc_dir = "/home/ubuntu/apps/cloud-crawler"
log_dir = "#{cc_dir}/logs"

log = Logger.new("#{log_dir}/master.log")

#TODO:  read from .s3cfg, hard code region

aws_access_key_id = `grep access_key /home/ubuntu/.s3cfg | awk '{print $3}'` 
aws_secret_access_key = `grep secret_key /home/ubuntu/.s3cfg | awk '{print $3}'` 
aws_region = 'us-west-1' 

c = Fog::Compute.new(
:provider => 'AWS',
:aws_access_key_id => aws_access_key_id,
:aws_secret_access_key => aws_secret_access_key,
:region => aws_region )

log.error 'stop-worker: can not connect' if c.nil?

worker = c.servers.select { |s| s.private_dns_name =~ /#{Socket.gethostname}/ }.first
log.info "stop-worker: stopping #{worker}"

worker.stop
