cc_dir = "/home/ubuntu/apps/cloud-crawler"
bin_dir = "#{cc_dir}/bin"
log_dir = "#{cc_dir}/logs"


every :hour do
   command "cd #{cc_dir}; sudo -E bundle exec  #{bin_dir}/restart_workers.rb ", :output => "#{log_dir}/master.log"
end


