#
# Cookbook Name:: papertrail
# Recipe:: default
#
# This recipe configures instances to send logs to Papertrail (papertrailapp.com)
# and installs the remote_syslog daemon to tail any log to the service.

# Turns out that syslog on EY images is too old to log to a port :(
# execute "configure syslog" do
#   command %{
#     echo '*.*          @logs.papertrailapp.com:50505' >> /etc/syslog.conf
#     killall -HUP syslogd
#   }
#   not_if { system("grep papertrailapp /etc/syslog.conf &> /dev/null") }
# end

# remote_syslog daemon to pass logs to papertrail
template "/etc/log_files.yml" do
  source "log_files.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  # PUT YOUR PORT NUMBER HERE
  variables(:port_number => '')
end

execute "install new enough of eventmachine" do
  # install manually because we get 0.12.6 and we need 0.12.10
  command %{gem install eventmachine}
  creates "/usr/lib/ruby/gems/1.8/cache/eventmachine-0.12.10.gem"
end

execute "install remote_syslog" do
  command %{gem install remote_syslog}
  creates "/usr/bin/remote_syslog"
end

# Automate running remote_syslog
remote_file "install remote_syslog init.d script" do
  action :create_if_missing
  path "/etc/init.d/remote_syslog"
  source "https://raw.github.com/papertrail/remote_syslog/master/examples/remote_syslog.init.d"
  owner "root"
  group "root"
  mode "0755"
end

execute "start remote_syslog at boot" do
  command %{rc-update add remote_syslog default}
  not_if { system("rc-update -s | grep remote_syslog &> /dev/null") }
end

execute "start or restart remote_syslog" do
  command %{/etc/init.d/remote_syslog restart}
end