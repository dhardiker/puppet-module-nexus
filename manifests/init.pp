# Class: nexus
#
#
class nexus(
  $base_dir     = '/opt',
  $run_as_user  = 'nexus',
  $remote_url   = 'http://www.sonatype.org/downloads/nexus-latest-bundle.tar.gz',
  $tar_name     = 'nexus-latest.tar.gz',
  $install_java = false,
  $work_backup  = false,
  $app_port     = '8081',
  $app_addr     = '0.0.0.0',
  $app_ctx_path = '/',
) {

  if $install_java == true {
    include java
  }

  $nexus_home = "${base_dir}/nexus"

  class { 'staging':
    path => '/opt/staging',
  }

  if !defined(User[$run_as_user]) {
    user { $run_as_user :
      ensure  => present,
      home    => $nexus_home,
    }

    User[$run_as_user] -> File[$nexus_home, "${base_dir}/sonatype-work"] -> Service['nexus']
  }

  if $work_backup != false {
    exec { "extract ${work_backup}":
      command   => "/bin/tar -zxf ${work_backup} && touch .sonatype-work.backup-extracted",
      cwd       => $base_dir,
      creates   => "${base_dir}/.sonatype-work.backup-extracted",
      logoutput => on_failure,
    }
  }

  staging::file { $tar_name:
    source => $remote_url,
  } ->

  exec { "extract ${tar_name}":
    command   => "/bin/tar --transform='s/nexus-[0-9]*.[0-9]*.[0-9]*-[0-9]*/nexus/' -xzf /opt/staging/nexus/${tar_name}",
    cwd       => $base_dir,
    creates   => $nexus_home,
    logoutput => on_failure,
  } ->

  file { $nexus_home:
    ensure  => directory,
    owner   => $run_as_user,
    group   => $run_as_user,
    mode    => '0775',
  } ->

  file { "${nexus_home}/conf/nexus.properties":
    ensure  => file,
    owner   => $run_as_user,
    group   => $run_as_user,
    mode    => '0775',
    content => template('nexus/nexus.properties.erb'),
  } ->

  file { "${base_dir}/sonatype-work":
    ensure  => directory,
    recurse => true,
    owner   => $run_as_user,
    group   => $run_as_user,
  } ->

  file { '/etc/init.d/nexus':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('nexus/nexus.init.erb'),
  } ->

  service { 'nexus':
    ensure => 'running',
  }

}
