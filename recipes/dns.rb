package 'dnscrypt-proxy'

apparmor_policy 'dnscrypt-proxy' do
  source_filename 'dns/usr.bin.dnscrypt-proxy.apparmor'
  notifies :restart, 'service[dnscrypt-proxy]', :immediately
end

%w(ip-blacklist.txt dnscrypt-proxy.toml).each do |src|
  template "/etc/dnscrypt-proxy/#{src}" do
    source "dns/#{src}.erb"
    notifies :restart, 'service[dnscrypt-proxy]', :immediately
  end
end

service 'dnscrypt-proxy' do
  action [ :enable, :start ]
end

# Adblocking

file '/etc/dnscrypt-proxy/adblock-urls' do
  content node['algo']['dns']['adblock']['urls']
  notifies :run, 'execute[adblock]', :immediately
end

template '/usr/local/bin/adblock.sh' do
  source 'dns/adblock.sh'
  notifies :run, 'execute[adblock]', :immediately
  mode '0755'
  only_if { node['algo']['dns']['adblock']['enabled'] }
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
