# include helper methods
class ::Chef::Recipe
  include ::Opscode::ChefClient::Helpers
end

# libraries/helpers.rb method to DRY directory creation resources
client_bin = find_chef_client
Chef::Log.debug("Found chef-client in #{client_bin}")
node.default['chef_client']['bin'] = client_bin
create_directories

dist_dir, conf_dir = value_for_platform_family(
  ['debian'] => %w( debian default ),
  ['fedora'] => %w( redhat sysconfig ),
  ['rhel'] => %w( redhat sysconfig ),
  ['suse'] => %w( suse sysconfig )
)

template '/etc/init.d/chef-client' do
  source "#{dist_dir}/init.d/chef-client.erb"
  mode 0755
  variables({
    :client_bin => client_bin,
    :chkconfig_start_order => node[:chef_client][chkconfig][start_order],
    :chkconfig_stop_order => node[:chef_client][chkconfig][stop_order]
  })
  notifies :restart, 'service[chef-client]', :delayed
end

template "/etc/#{conf_dir}/chef-client" do
  source "#{dist_dir}/#{conf_dir}/chef-client.erb"
  mode 0644
  notifies :restart, 'service[chef-client]', :delayed
end

service 'chef-client' do
  supports status: true, restart: true
  action [:enable, :start]
end
