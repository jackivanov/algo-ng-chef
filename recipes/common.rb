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
  notifies :restart, 'service[systemd-resolved]', :immediately
end

%w(systemd-networkd systemd-resolved).each do |svc|
  service svc do
    action [ :enable, :start ]
  end
end

# Iptabless

template '/etc/iptables/rules.v4' do
  source 'common/iptables-rules.v4.erb'
  notifies :restart, 'service[netfilter-persistent]', :immediately
end

service 'netfilter-persistent' do
  action [ :enable, :start ]
end
