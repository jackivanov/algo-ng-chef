default['apt']['confd']['install_recommends'] = true
default['apt']['unattended_upgrades']['enable'] = true
default['apt']['unattended_upgrades']['automatic_reboot'] = true
default['apt']['unattended_upgrades']['automatic_reboot_time'] = '06:00'
default['apt']['unattended_upgrades']['update_package_lists'] = true
default['apt']['unattended_upgrades']['allowed_origins']= [
  "o=${distro_id},n=${distro_codename}-security",
  "o=${distro_id},n=${distro_codename}-updates",
]
