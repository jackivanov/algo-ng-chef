if ENV['TEST_KITCHEN']
  override['algo']['common']['endpoint'] = node['ec2']['public_ipv4']
end
