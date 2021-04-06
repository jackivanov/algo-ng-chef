default['algo']['wireguard'] = {
  'enabled' => true,
  'ipv4' => '10.200.0.1/16',
  'ipv6' => 'fd9d:bc11:4021::1/64',
  'generate_keys' => false,
  'exposed_port' => 51820,
}

default['algo']['wireguard']['config'] = {
  'ServerAddress' => 'localhost',
  'Interface' => {
    'Address' => [
      IPAddress(node['algo']['wireguard']['ipv4']).first.address,
    ],
    'ListenPort' => 51820,
    'PrivateKey' => nil,
  },
  'Peers' => nil,
}

