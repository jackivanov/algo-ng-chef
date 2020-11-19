default['algo']['ipv4'] = node['network']['default_gateway'] ? true : false
default['algo']['ipv6'] = node['network']['default_inet6_gateway'] ? true : false
default['algo']['common']['packages'] = [
  'coreutils',
  'iptables-persistent',
  'cgroup-tools',
  'openssl',
]

default['algo']['common']['sysctl'] = {
  "net.ipv4.ip_forward" => 1,
  "net.ipv4.conf.all.forwarding" => 1,
  "net.ipv6.conf.all.forwarding" => 1,
}

default['algo']['users'] = [
  'phone',
  'laptop',
  'desktop',
]

default['algo']['common']['endpoint'] = '8.8.8.8'
