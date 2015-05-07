# See README.md for details.
class openldap::client::utils(
  $package = $::osfamily ? {
    'Debian' => 'ldap-utils',
    'RedHat' => 'openldap-clients',
  },
) {
  if ! defined(Package[$package]) {
    package { $package:
      ensure => present,
    }
  }
}
