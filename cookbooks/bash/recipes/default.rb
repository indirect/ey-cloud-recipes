#
# Cookbook Name:: bash_profile
# Recipe:: default
#

template "/home/deploy/.bash_profile" do
  owner "deploy"
  group "deploy"
  mode 0644
  source "bash_profile.erb"
  variables({
    # info about this instance
    :environment => node[:environment][:name],
    :instance_role => node[:instance_role],
    :server_name => node[:name],
    # info about the first app
    :app_name => node[:engineyard][:environment][:apps].first[:name],
    :framework_env => node[:environment][:framework_env]
  })
end