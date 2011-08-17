#
# Cookbook Name:: papertrail
# Recipe:: default
#
# This recipe configures instances to send logs to Papertrail (papertrailapp.com)
# and installs the remote_syslog daemon to tail any log to the service.
# A second remote_syslog daemon to monitor /var/log/syslog is included because
# the syslog version on EY instances is too old to support logging to a given
# port. That means syslog to Papertrail won't work, so we work around it.

PORT_NUMBER = 'XXXXX'

app_name = node[:applications].keys.first
env = node[:environment][:framework_env]
PAPERTRAIL_CONFIG = {
  :port_number => PORT_NUMBER,
  :hostname => "#{app_name}_#{env[0..0]}_#{`hostname`.chomp}"
}

execute "install remote_syslog gem from rubygems" do
  command %{gem install remote_syslog -v "~>1.2"}
  creates "/usr/bin/remote_syslog"
end

# remote_syslog daemons, one to handle regular logs,
%w(default syslog).each do |name|
  # remote_syslog config file
  template "/etc/log_files_#{name}.yml" do
    source "log_files_#{name}.yml.erb"
    mode "0644"
    variables(PAPERTRAIL_CONFIG)
  end

  # init.d config file
  template "/etc/conf.d/remote_syslog_#{name}" do
    source "remote_syslog.confd.erb"
    mode "0644"
    # Giving the default remote_syslog a custom pid works around a bug
    # in Daemons that prevents it from starting after other copies.
    variables(
      :config => "/etc/log_files_#{name}.yml",
      :name => "remote_syslog_#{name}")
  end

  # init.d script
  template "/etc/init.d/remote_syslog_#{name}" do
    source "remote_syslog.initd.erb"
    mode "0755"
  end

  # start at boot
  execute "start remote_syslog_#{name} at boot" do
    command %{rc-update add remote_syslog_#{name} default}
    creates "/etc/runlevels/default/remote_syslog_#{name}"
  end

  # start right now
  execute "start or restart remote_syslog" do
    command %{/etc/init.d/remote_syslog_#{name} restart}
  end
end
