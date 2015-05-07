# See README.md for Details

define openldap::server::schema (
  $ensure = undef,
  $path = $::osfamily ? {
    'Debian' => "/etc/ldap/schema/${title}.schema",
    'Redhat' => "/etc/openldap/schema/${title}.schema",
  }
) {

  if ! defined(Class['openldap_server']) {
    fail 'class ::openldap::server has not been evaluated'
  }

  if $::openldap::server::provider == 'augeas' {
    Class['openldap::server::install'] ->
    Openldap::Server::Schema[$title] ->
    Class['openldap::server::service]
  } else {
    Class['openldap::server::service] ->
    Openldap::Server::Schema[$title] ->
    Class['openldap::server]
  }

  if $path {
    $path_with_default = $path
  } else {
    $path_with_default = $::osfamily ? {
      'Debian' => "/etc/ldap/schema/${title}.schema",
      'Redhat' => "/etc/openldap/schema/${title}.schema",
      default  => "/etc/ldap/schema/${title}.schema",
    }
  }

  openldap_schema { $title:
    ensure   => $ensure,
    path     => $path_with_default,
    provider => $::openldap::server::provider,
  }
}

