default['algo']['dns']['adblock'] = {
  'enabled' => true,
  'urls' => <<-EOF
    https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
    https://hosts-file.net/ad_servers.txt
  EOF
}

default['algo']['dns']['servers'] = {
  'ipv4' => [
    '1.1.1.1',
    '1.0.0.1',
  ],
  'ipv6' => [
    '2606:4700:4700::1111',
    '2606:4700:4700::1001',
  ]
}

default['algo']['dns']['dnscrypt'] = {
  'enabled' => true,
  'servers' => {
    'ipv4' => [
      'cloudflare',
    ],
    'ipv6' => [
      'cloudflare-ipv6',
    ]
  }
}

