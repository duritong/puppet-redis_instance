# base setup for redis instances
class redis_instance::base {
  include redis::params
  include redis::preinstall
  include redis::install
  selinux::policy{
    'redis_instance':
      fc_file   => true,
      te_source => 'puppet:///modules/redis_instance/selinux_policy/redis_instance.te',
      fc_source => 'puppet:///modules/redis_instance/selinux_policy/redis_instance.fc',
  }
}
