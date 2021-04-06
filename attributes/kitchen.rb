if ENV['TEST_KITCHEN']
  override['algo']['wireguard']['config']['ServerAddress'] = node['ec2']['public_ipv4']
end
