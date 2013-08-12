#
# Copyright (c) 2013 Charles H Martin, PhD
#  
#  Calculated Content 
#  http://calculatedcontent.com
#  charles@calculatedcontent.com
#
cc_dir = "/home/ubuntu/cc/cloud-crawler"
bin_dir = "#{cc_dir}/bin"
log_dir = "#{cc_dir}/logs"


every 10.minutes do
   command "cd #{cc_dir}; sudo -E bundle exec  #{bin_dir}/restart_workers.rb ", :output => "#{log_dir}/master.log"
end


