package 'wireguard'

template '/etc/wireguard/wg0.conf' do
  source 'wireguard/wg0.conf.erb'
  # variables(
  #   Address: 1.1.1.1
  # )
end
