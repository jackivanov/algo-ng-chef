package 'wireguard'

require 'inifile'
require 'x25519'

#
# Server Config
#

wg0_conf = IniFile.load('/etc/wireguard/wg0.conf')
if node['algo']['wireguard']['config']['Interface']['PrivateKey']
  Server_PrivateKey = node['algo']['wireguard']['config']['Interface']['PrivateKey']
  Server_PublicKey = Base64.encode64(X25519::Scalar.new(Base64.decode64(Server_PrivateKey)).public_key.to_bytes).chomp
elsif wg0_conf && wg0_conf['Interface']['PrivateKey']
  Server_PrivateKey = wg0_conf['Interface']['PrivateKey']
  Server_PublicKey = Base64.encode64(X25519::Scalar.new(Base64.decode64(Server_PrivateKey)).public_key.to_bytes).chomp
elsif supplied_key
  Server_PrivateKey = supplied_key
  Server_PublicKey = Base64.encode64(X25519::Scalar.new(Base64.decode64(Server_PrivateKey)).public_key.to_bytes).chomp
else
  generated_key = X25519::Scalar.generate
  Server_PrivateKey = Base64.encode64(generated_key.to_bytes).chomp
  Server_PublicKey = Base64.encode64(generated_key.public_key.to_bytes).chomp
end

Server_Peers = []
node['algo']['users'].each_with_index do |user, index|
  configFile = "/etc/wireguard/.#{user}.json"
  config = JSON.parse(File.read(configFile)) rescue nil

  if !config
    # Generate random IP using username as the seed for idempotence
    user_uniq_id = user.unpack("B*")[0].to_i(2)
    srand(user_uniq_id)
    term = rand(65534)

    privateKey = X25519::Scalar.generate
    h = {
      'Name' => user,
      'Address' => [
        (IPAddress(IPAddress(node['algo']['wireguard']['ipv4']).to_i + 2 + term)).to_string,
      ],
      'PrivateKey' => Base64.encode64(privateKey.to_bytes).chomp,
      'PublicKey' => Base64.encode64(privateKey.public_key.to_bytes).chomp,
    }

    Server_Peers += [h]

    file configFile do
      content Chef::JSONCompat.to_json_pretty(h)
    end
  else
    Server_Peers += [config]
  end
end

template '/etc/wireguard/wg0.conf' do
  source 'wireguard/wg0.conf.erb'
  variables(
    :Interface => {
      'PrivateKey' => Server_PrivateKey
    },
    :Peers => Server_Peers
  )
end

Server_Peers.each do |peer|
  template "/etc/wireguard/.#{peer['Name']}.conf" do
    source 'wireguard/user.wg.erb'
    variables(
      :Interface => {
        'PrivateKey' => peer['PrivateKey'],
        'Address' => peer['Address'],
        'DNS' => node['algo']['dns']['dnscrypt']['enabled'] ? node['algo']['dns']['servers']['ipv4'] : node['algo']['wireguard']['config']['Interface']['Address']
      },
      :Peer => {
        'PublicKey' => Server_PublicKey,
        'Endpoint' => node['algo']['wireguard']['config']['Interface']['Address'][0]
      }
    )
  end
end
