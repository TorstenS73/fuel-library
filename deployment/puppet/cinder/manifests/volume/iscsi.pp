#
class cinder::volume::iscsi (
  $iscsi_ip_address,
  $volume_group      = 'cinder-volumes',
  $iscsi_helper      = 'tgtadm',
) {

  include cinder::params

  cinder_config {
    'DEFAULT/iscsi_ip_address': value => $iscsi_ip_address;
    'DEFAULT/iscsi_helper':     value => $iscsi_helper;
    'DEFAULT/volume_group':     value => $volume_group;
   }

  case $iscsi_helper {
    'tgtadm': {
      package { 'tgt':
        name   => $::cinder::params::tgt_package_name,
        ensure => present,
      }
      service { 'tgtd':
        name    => $::cinder::params::tgt_service_name,
        ensure  => running,
        enable  => true,
        require => Class['cinder::volume'],
      }
    }

    'ietadm': {
      package { ['iscsitarget', 'iscsitarget-dkms']:
        # name   => $::nova::params::iet_package_name,
        ensure => present,
      }

      exec { 'enable_iscsitarget':
        command => "/bin/sed -i 's/false/true/g' /etc/default/iscsitarget",
        unless  => "/bin/grep -q true /etc/default/iscsitarget",
        require => Package['iscsitarget'],
        notify  => Service['iscsitarget'],
      }

      service { 'iscsitarget':
        name     => $::nova::params::iet_service_name,
        # provider => $::nova::params::special_service_provider,
        ensure   => running,
        enable   => true,
        require  => [Class['cinder::volume'], Package['iscsitarget', 'iscsitarget-dkms']],
      }
    }

    default: {
      fail("Unsupported iscsi helper: ${iscsi_helper}.")
    }
  }

}
