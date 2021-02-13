require 'x25519'

package %w(wireguard qrencode)

#
# Generate users config files
#

server_peers = []
node['algo']['users'].each_with_index do |user, index|
  client_config_file = "/etc/wireguard/pki/.#{user}.json"
  client_config_json = JSON.parse(File.read(client_config_file)) rescue false

  if !client_config_json
    # Generate random IP using username as the seed for idempotence
    user_uniq_id = user.unpack("B*")[0].to_i(2)
    srand(user_uniq_id)
    term = rand(65534)

    privatekey = X25519::Scalar.generate
    ipv4 = IPAddress(node['algo']['wireguard']['ipv4'])
    client_config_json = {
      'Name' => user,
      'Address' => [
        "#{(IPAddress(ipv4.to_i + 2 + term)).to_s}/#{ipv4.prefix}",
      ],
      'PrivateKey' => Base64.encode64(privatekey.to_bytes).chomp,
      'PublicKey' => Base64.encode64(privatekey.public_key.to_bytes).chomp,
    }

    file client_config_file do
      content Chef::JSONCompat.to_json_pretty(client_config_json)
      mode '0600'
    end
  end

  server_peers += [client_config_json]

  template "/etc/wireguard/pki/wg0.#{user}.conf" do
    source 'wireguard/user.wg.erb'
    mode '0600'
    variables(
      :Interface => {
        'PrivateKey' => client_config_json['PrivateKey'],
        'Address' => client_config_json['Address'],
        'DNS' => node['algo']['dns']['dnscrypt']['enabled'] ? 
          node['algo']['wireguard']['config']['Interface']['Address'] : 
          node['algo']['dns']['servers']['ipv4']
      },
      :Peer => {
        'PublicKey' => server_publickey,
        'Endpoint' => "#{node['algo']['common']['endpoint']}:#{node['algo']['wireguard']['config']['Interface']['ListenPort']}"
      }
    )
  end

  %w(ansiutf8 png).each do |type|
    execute "qrencode #{type}" do
      command "/usr/bin/qrencode -t #{type} -r wg0.#{user}.conf -o wg0.#{user}.qr.#{type}"
      creates "wg0.#{user}.qr.#{type}"
      cwd '/etc/wireguard/pki/'
      umask '077'
    end
  end
end

#
# Generate server config file
#

template '/etc/wireguard/wg0.conf' do
  source 'wireguard/wg0.conf.erb'
  mode '0600'
  variables(
    :Interface => {
      'PrivateKey' => server_privatekey
    },
    :Peers => server_peers
  )
  notifies :restart, 'service[wg-quick@wg0]', :immediately
end

service 'wg-quick@wg0' do
  action [ :enable, :start ]
end
