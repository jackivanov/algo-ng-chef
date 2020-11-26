require 'x25519'

package %w(wireguard qrencode)
directory '/etc/wireguard/pki/' do
  mode '0700'
end

#
# Generate server private key
#

server_config_dump = '/etc/wireguard/pki/.wg0.json'
server_config_json = JSON.parse(File.read(server_config_dump)) rescue false

if node['algo']['wireguard']['config']['Interface']['PrivateKey']
  server_privatekey = node['algo']['wireguard']['config']['Interface']['PrivateKey']
  server_publickey = Base64.encode64(X25519::Scalar.new(Base64.decode64(server_privatekey)).public_key.to_bytes).chomp
elsif server_config_json && server_config_json['PrivateKey']
  server_privatekey = server_config_json['PrivateKey']
  server_publickey = Base64.encode64(X25519::Scalar.new(Base64.decode64(server_privatekey)).public_key.to_bytes).chomp
else
  generated_key = X25519::Scalar.generate
  server_privatekey = Base64.encode64(generated_key.to_bytes).chomp
  server_publickey = Base64.encode64(generated_key.public_key.to_bytes).chomp

  file server_config_dump do
    mode '0600'
    content Chef::JSONCompat.to_json_pretty({
      'PrivateKey' => server_privatekey,
      'PublicKey' => server_publickey,
    })
  end
end

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
