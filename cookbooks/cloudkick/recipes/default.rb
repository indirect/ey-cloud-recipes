#
# Cookbook Name:: cloudkick
# Recipe:: default
#

template "/etc/cloudkick.conf" do
  source "cloudkick.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    # Fill in your configuration here
    :oauth_key => 'YOUR_KEY',
    :oauth_secret => 'YOUR_SECRET'
  )
end

directory "/usr/portage/local" do
  owner "root"
  group "root"
  mode 0755
end

bash "clone cloudkick-engineyard" do
  user "root"
  cwd "/usr/portage/local"
  code %{git clone https://github.com/cloudkick/cloudkick-engineyard.git}
  not_if { File.exists? "/usr/portage/local/cloudkick-engineyard" }
end

execute "configure overlay" do
  command %{echo 'PORTDIR_OVERLAY="${PORTDIR_OVERLAY} /usr/portage/local/cloudkick-engineyard"' >> /etc/make.conf}
  not_if { system("grep cloudkick-engineyard /etc/make.conf > /dev/null") }
end

execute "emerge cloudkick-agent" do
  command %{emerge cloudkick-agent}
  not_if { File.exists? "/usr/sbin/cloudkick-agent" }
end

execute "start cloudkick-agent at boot" do
  command %{rc-update add cloudkick-agent default}
  not_if { system("rc-update -s | grep cloudkick-agent > /dev/null") }
end

execute "start cloudkick-agent" do
  command %{/etc/init.d/cloudkick-agent start}
  not_if { system("/etc/init.d/cloudkick-agent status | grep started > /dev/null") }
end
