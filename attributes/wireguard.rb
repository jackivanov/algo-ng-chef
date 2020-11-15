default['algo']['wireguard'] = {
  'enabled' => true,
  'ipv4' => "10.200.0.0/16",
  'ipv6' => "fd9d:bc11:4021::/64",
}

default['algo']['wireguard']['config'] = {
  'Interface' => {
    'Address' => [
      IPAddress(node['algo']['wireguard']['ipv4']).first.to_string,
      node['algo']['ipv4'] ? IPAddress(node['algo']['wireguard']['ipv6']).first.to_string : []
    ],
    'ListenPort' => 51820,
    'PrivateKey' => nil,
  },
  'Peers' => [
    'PublicKey' => nil,
    'PresharedKey' => nil,
    'AllowedIPs' => nil,
  ],
}
