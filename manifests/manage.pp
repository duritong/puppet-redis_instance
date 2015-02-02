# redis instance
define redis_instance::manage(
  $port                       = undef,
  $ensure                     = 'present',
  $redis_user                 = $name,
  $redis_group                = $name,
  $disk_size                  = '1G',
  $bind                       = '127.0.0.1',
  $databases                  = 16,
  $dbfilename                 = 'dump.rdb',
  $hash_max_ziplist_entries   = 512,
  $hash_max_ziplist_value     = 64,
  $list_max_ziplist_entries   = 512,
  $list_max_ziplist_value     = 64,
  $log_level                  = 'notice',
  $maxclients                 = 10000,
  $maxmemory                  = undef,
  $maxmemory_policy           = undef,
  $maxmemory_samples          = undef,
  $no_appendfsync_on_rewrite  = false,
  $port                       = 6379,
  $rdbcompression             = true,
  $requirepass                = undef,
  $set_max_intset_entries     = 512,
  $slowlog_log_slower_than    = 10000,
  $slowlog_max_len            = 1024,
  $syslog_enabled             = undef,
  $syslog_facility            = undef,
  $timeout                    = 0,
  $ulimit                     = 65536,
  $zset_max_ziplist_entries   = 128,
  $zset_max_ziplist_value     = 64,
  $masterauth                 = undef,
  $repl_ping_slave_period     = 10,
  $repl_timeout               = 60,
  $slave_read_only            = true,
  $slave_serve_stale_data     = true,
  $slaveof                    = undef,
){

  $service_name = "redis-${name}"
  $systemd_file = "/etc/systemd/system/${service_name}.service"
  $config_file  = "/etc/${service_name}.conf"
  $log_dir      = "/var/log/${service_name}"
  $log_file     = "${log_dir}/redis.log"
  $workdir      = "/var/lib/${service_name}"
  $daemonize    = false
  $pid_dir      = "/var/run/${service_name}"
  $pid_file     = "${pid_dir}/redis-server.pid"
  group{$redis_group:
    ensure => $ensure
  }
  user{$redis_user:
    ensure     => $ensure,
    gid        => $redis_group,
    home       => $workdir,
    managehome => false,
    shell      => '/sbin/nologin',
    comment    => "Redis instance ${name}",
  } -> file{[$systemd_file,$config_file,$log_dir,$pid_dir]: }

  disks::lv_mount{
    $service_name:
      ensure => $ensure,
      size   => $disk_size,
      folder => $workdir,
  }
  service{$service_name: }

  if $ensure == 'present' {
    if !$port { fail("You must set \$port for ${name}") }
    require redis_instance::base
    Group[$redis_group] -> User[$redis_user]

    if $port != 6379 {
      selinux::seport{
        $port:
          setype => 'redis_port_t';
      }
    }

    Disks::Lv_mount[$service_name]{
      owner => $redis_user,
      group => $redis_group,
      mode  => '0640',
    }

    File[$log_dir,$pid_dir]{
      ensure => directory,
      owner  => $redis_user,
      group  => $redis_group,
      mode   => '0640',
    }
    File[$config_file]{
      content => template('redis/redis.conf.erb'),
      owner   => root,
      group   => $redis_group,
      mode    => '0640',
      require => Disks::Lv_mount[$service_name],
      notify  => Service[$service_name],
    }
    File[$systemd_file]{
      content => template('redis_instance/systemd/redis-instance.erb'),
      require => File[$config_file],
      owner   => root,
      group   => 0,
      mode    => '0644'
    }
    Service[$service_name]{
      ensure  => running,
      enable  => true,
      require => File[$systemd_file],
    }
  } else {
    User[$redis_user] -> Group[$redis_group]
    Service[$service_name] {
      ensure => stopped,
      enable => false
    }
    File[$systemd_file,$config_file,$log_dir,$pid_dir]{
      ensure  => absent,
      purge   => true,
      force   => true,
      recurse => true,
      require => Service[$service_name]
    }
    Disks::Lv_mount[$service_name]{
      require => Service[$service_name]
    }
  }

}
