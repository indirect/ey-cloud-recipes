#
# Cookbook Name:: cloudkick
# Recipe:: default
#

# Config file for the cloudkick agent, including tags for the node type and environment
template "/etc/cloudkick.conf" do
  source "cloudkick.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    # Fill in your configuration here
    :oauth_key => 'YOUR_KEY',
    :oauth_secret => 'YOUR_SECRET'
    :tags => [
      node[:instance_role],
      node[:name],
      node[:environment][:name]
    ].compact
  )
end

# Create the directory for cloudkick's portage overlay
directory "/usr/portage/local" do
  owner "root"
  group "root"
  mode 0755
end

# Clone the portage overlay
bash "clone cloudkick-engineyard" do
  user "root"
  cwd "/usr/portage/local"
  code %{git clone https://github.com/cloudkick/cloudkick-engineyard.git}
  not_if { File.exists? "/usr/portage/local/cloudkick-engineyard" }
end

# Configure portage to use the overlay
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
  command %{/etc/init.d/cloudkick-agent restart}
end

app_server = ["solo", "app_master", "app"].include?(node[:instance_role])
if app_server
  # Configure nginx to allow status requests for cloudkick to graph
  template "/etc/nginx/servers/nginx_status.conf" do
    source "nginx_status.conf.erb"
    owner "deploy"
    group "deploy"
    mode 0644
  end

  execute "reload nginx configuration" do
    command %{/etc/init.d/nginx reload}
  end

  # Configure passenger monitoring plugin
  passenger = node[:environment][:stack].include?("passenger3")
  if passenger
    directory "/usr/lib/cloudkick-agent/plugins" do
      recursive true
    end

    template "/usr/lib/cloudkick-agent/plugins/passenger.rb" do
      source "passenger.rb.erb"
      mode "0755"
    end
  end

end
