# base setup for redis instances
class redis_instance::base {
  class{'redis':
    service_ensure => 'stopped',
    service_enable => false,
  }
  selinux::policy{
    'redis_instance':
      fc_file   => true,
      te_source => 'puppet:///modules/redis_instance/selinux_policy/redis_instance.te',
      fc_source => 'puppet:///modules/redis_instance/selinux_policy/redis_instance.fc',
  }
}
