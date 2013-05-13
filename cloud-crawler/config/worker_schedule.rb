cc_dir = "/home/ubuntu/apps/cloud-crawler/cloud-crawler"
bin_dir = "#{cc_dir}/bin"
log_dir = "#{cc_dir}/logs"

master_ip = ENV['MASTER_IP_ADDRESS']

every :reboot do
   command "cd #{cc_dir}; sudo -E bundle exec  #{bin_dir}/run_worker.rb -h #{master_ip}", :output => "#{log_dir}/worker.log"
end

