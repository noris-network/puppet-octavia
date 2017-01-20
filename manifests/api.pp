# Installs & configure the octavia service
#
# == Parameters
#
# [*enabled*]
#   (optional) Should the service be enabled.
#   Defaults to true
#
# [*manage_service*]
#   (optional) Whether the service should be managed by Puppet.
#   Defaults to true.
#
# [*host*]
#   (optional) The octavia api bind address.
#   Defaults to 0.0.0.0
#
# [*port*]
#   (optional) The octavia api port.
#   Defaults to 9876
#
# [*package_ensure*]
#   (optional) ensure state for package.
#   Defaults to 'present'
#
# [*sync_db*]
#   (optional) Run octavia-db-manage upgrade head on api nodes after installing the package.
#   Defaults to false
#
# [*service_ensure*]
#   (optional) Ensure service is in given state f.e. 'running'
#   Defaults to 'running'
#

class octavia::api (
  $manage_service        = true,
  $enabled               = true,
  $package_ensure        = 'present',
  $host                  = '0.0.0.0',
  $port                  = '9876',
  $sync_db               = false,
  $service_ensure        = 'running',
) inherits octavia::params {

  include ::octavia::policy

  Package['octavia-api'] -> Class['octavia::policy']
  package { 'octavia-api':
    ensure => $package_ensure,
    name   => $::octavia::params::api_package_name,
    tag    => ['openstack', 'octavia-package'],
  }

  if $manage_service {
    Octavia_config<||> ~> Service['octavia-api']
    Class['octavia::policy'] ~> Service['octavia-api']
    Package['octavia-api'] -> Service['octavia-api']

    service { 'octavia-api':
      ensure     => $service_ensure,
      name       => $::octavia::params::api_service_name,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      require    => Class['octavia::db'],
      tag        => ['octavia-service', 'octavia-db-sync-service'],
    }
  }

  if $sync_db {
    include ::octavia::db::sync
  }


  octavia_config {
    'DEFAULT/bind_host'                             : value => $host;
    'DEFAULT/bind_port'                             : value => $port;
  }

}
