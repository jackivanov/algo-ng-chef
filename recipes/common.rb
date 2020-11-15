include_recipe 'apt::default'
include_recipe 'apt::unattended-upgrades'
include_recipe 'apparmor::default'

package node['algo']['common']['packages']

node['algo']['common']['sysctl'].each do |k, v|
  sysctl k do
    key k
    value v
  end
end

template '/etc/systemd/resolved.conf' do
  source 'common/resolved.conf.erb'
  notifies :run, 'service[systemd-resolved]', :immediately
end

%w(systemd-networkd systemd-resolved).each do |svc|
  service svc do
    action [ :enable, :start ]
  end
end
