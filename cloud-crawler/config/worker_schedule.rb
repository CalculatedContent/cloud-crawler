cc_dir = "/home/ubuntu/cc/cloud-crawler"
bin_dir = "#{cc_dir}/bin"
log_dir = "#{cc_dir}/logs"

# @master_ip_address is set on the command line by whenever in the start_worker recipe
# otherwise the default should be the local host

every :reboot do
   command "cd #{cc_dir};  sudo -E bundle exec  #{bin_dir}/run_worker.rb -h #{@master_ip_address}", :output => "#{log_dir}/worker.log"
end

