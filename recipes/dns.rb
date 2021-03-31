package 'dnscrypt-proxy'

apparmor_policy 'dnscrypt-proxy' do
  source_filename 'dns/usr.bin.dnscrypt-proxy.apparmor'
  notifies :restart, 'service[dnscrypt-proxy.service]', :immediately
end

%w(ip-blacklist.txt dnscrypt-proxy.toml).each do |src|
  template "/etc/dnscrypt-proxy/#{src}" do
    source "dns/#{src}.erb"
    notifies :restart, 'service[dnscrypt-proxy.service]', :immediately
  end
end

directory '/etc/systemd/system/dnscrypt-proxy.socket.d/'
template '/etc/systemd/system/dnscrypt-proxy.socket.d/algo.conf' do
  source 'dns/algo.socket.erb'
  notifies :run, 'execute[daemon-reload]', :immediately
  notifies :restart, 'service[dnscrypt-proxy.socket]', :immediately
  notifies :restart, 'service[dnscrypt-proxy.service]', :immediately
end

%w(dnscrypt-proxy.service dnscrypt-proxy.socket).each do |svc|
  service svc do
    action [ :enable, :start ]
  end
end

# Adblocking

template '/usr/local/bin/adblock.sh' do
  source 'dns/adblock.sh'
  notifies :run, 'execute[adblock]', :immediately
  mode '0755'
  only_if { node['algo']['dns']['adblock']['enabled'] }
end

file '/etc/dnscrypt-proxy/adblock-urls' do
  content node['algo']['dns']['adblock']['urls'].join("\n")
  notifies :run, 'execute[adblock]', :immediately
end

cron 'adblock' do
  hour '2'
  minute '10'
  command '/usr/local/bin/adblock.sh'
  only_if { node['algo']['dns']['adblock']['enabled'] }
end

execute 'adblock' do
  command '/usr/local/bin/adblock.sh'
  action :nothing
  only_if { node['algo']['dns']['adblock']['enabled'] }
end

execute 'daemon-reload' do
  command '/usr/bin/systemctl daemon-reload'
  action :nothing
end

# TODO: systemd socket activation
