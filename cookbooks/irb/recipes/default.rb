#
# Cookbook Name:: irb
# Recipe:: default
#

template "/home/deploy/.irbrc" do
  owner "deploy"
  group "deploy"
  mode 0644
  source "irbrc.erb"
end