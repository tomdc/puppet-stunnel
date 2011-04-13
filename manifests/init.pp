#
# This module manages stunnel
#
class stunnel {
  if ( $operatingsystem == "Solaris" ) {
    # if Solaris do a bunch of things
    include stunnel::solaris
  }
  else {
    # just make sure the package is installed
    package{"stunnel":
      ensure => installed
    }
  }
}

class stunnel::solaris {
  # pkg needs to be installed, using pkgutil
  package{"stunnel":
    provider => 'pkgutil',
    ensure => installed
  }

  # permissions
  # stunnel.conf creates pid in /opt/csw/var/run
  # make sure permissions are set in a way user nobody can create a file there
  file {
    "/opt/csw/var":
      ensure => directory,
      mode => 775;
    "/opt/csw/var/run":
      ensure => directory,
      owner => "root",
      group => "sys",
      mode => 775;
    # the stunnel manifest
    "/opt/csw/var/svc/manifest/stunnel.xml":
      ensure => present,
      source => "puppet:///stunnel/solaris_stunnel.xml",
      require => Package["stunnel"];
  }

  # import the manifest, make sure perms are set ok first
  # only run when perms are not as mentioned above (first install or even after installing csw pkgs perms on /opt/csw/var are changed again
  # This is not a nice way, but it is only executed once
  exec { "svccfg import /opt/csw/var/svc/manifest/stunnel.xml":
    require => [ File["/opt/csw/var/svc/manifest/stunnel.xml"], File["/opt/csw/var"], File["/opt/csw/var/run"] ],
    path => "/usr/bin:/usr/sbin:/bin",
    refreshonly => true,
    subscribe => [ File["/opt/csw/var"], File["/opt/csw/var/svc/manifest/stunnel.xml"] ],
  }

  # make sure the service is running
  service { "svc:/application/stunnel:default":
    provider => "smf",
    ensure => running,
    require => [ File["/opt/csw/var/run"], Exec["svccfg import /opt/csw/var/svc/manifest/stunnel.xml"] ],
  }
}
