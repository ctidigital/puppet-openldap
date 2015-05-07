# See README.md for details.
define openldap::server::dbconfig(
  $ensure => undef,  
  $target => regsubst($title, '^(\S+)\s+on\s+(\S+)$', '\1'),
  $suffix => regsubst($title, '^(\S+)\s+on\s+(\S+)$', '\2'),
  $value,
) {

  if ! defined(Class['openldap::server']) {
    fail 'class ::openldap::server has not been evaluated'
  }

  if $::openldap::server::provider == 'augeas' {
    fail 'resource openldap::server::dbconfig is only valid for olc provider'
  } else {
    Class['openldap::server::service'] ->
    Openldap::Server::Overlay[$title] ->
    Class['openldap::server']
  }
  openldap_dbconfig { $name:
    provider => $::openldap::server::provider,
    suffix   => $suffix,
    target   => $target,
    value    => $value,
  }
}
