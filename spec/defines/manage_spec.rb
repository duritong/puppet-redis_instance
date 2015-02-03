require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'redis_instance::manage', :type => 'define' do
  let(:title) { 'test' }
  let(:facts) {
    {
      :virtual => 'kvm',
    }
  }
  context "with default values" do
    let(:params){
      {
        :port => 6380,
      }
    }
    it { should contain_group('redis-test').with(
      :ensure => 'present',
      :before => 'User[redis-test]'
    )}
    it { should contain_user('redis-test').with(
      :ensure => 'present',
      :gid    => 'redis-test',
      :home   => '/var/lib/redis-test',
      :managehome => false,
      :shell => '/sbin/nologin',
      :comment => "Redis instance test",
      :before  => ['File[/etc/systemd/system/redis-test.service]',
        'File[/etc/redis-test.conf]', 'File[/var/log/redis-test]',
        'File[/var/run/redis-test]']
    )}
    it { should contain_disks__lv_mount('redis-test').with(
      :ensure  => 'present',
      :size    => '1G',
      :folder  => '/var/lib/redis-test',
      :owner   => 'redis-test',
      :group   => 'redis-test',
      :mode    => '0750',
      :seltype => 'redis_var_lib_t'
    )}
    it { should contain_class('redis_instance::base') }
    it { should contain_selinux__seport('6380').with(
      :setype => 'redis_port_t',
      :before => 'Service[redis-test]'
    )}
    it { should contain_file('/var/log/redis-test').with(
      :ensure  => 'directory',
      :owner   => 'redis-test',
      :group   => 'redis-test',
      :mode    => '0640',
      :seltype => 'redis_log_t'
    )}
    it { should contain_file('/var/run/redis-test').with(
      :ensure  => 'directory',
      :owner   => 'redis-test',
      :group   => 'redis-test',
      :mode    => '0640',
      :seltype => 'redis_var_run_t'
    )}
    it { should contain_file('/etc/systemd/system/redis-test.service').with(
      :owner   => 'root',
      :group   => 0,
      :mode    => '0644',
      :seltype => 'redis_unit_file_t',
      :require => 'File[/etc/redis-test.conf]'
    )}
    it { should contain_file('/etc/redis-test.conf').with(
      :owner   => 'root',
      :group   => 'redis-test',
      :mode    => '0640',
      :require => 'Disks::Lv_mount[redis-test]',
      :notify  => 'Service[redis-test]'
    )}
    it { should contain_service('redis-test').with(
      :ensure  => 'running',
      :enable  => true,
      :require => 'File[/etc/systemd/system/redis-test.service]'
    )}
  end
  context "with default port" do
    let(:params){
      {
        :port => 6379,
      }
    }
    it { should_not contain_selinux__seport('6380') }
  end

  context 'with absent' do
    let(:params){
      {
        :ensure => 'absent',
      }
    }
    it { should contain_group('redis-test').with(
      :ensure => 'absent',
    )}
    it { should contain_user('redis-test').with(
      :ensure => 'absent',
      :gid    => 'redis-test',
      :home   => '/var/lib/redis-test',
      :managehome => false,
      :shell => '/sbin/nologin',
      :comment => "Redis instance test",
      :before  => ['File[/etc/systemd/system/redis-test.service]',
                   'File[/etc/redis-test.conf]',
                   'File[/var/log/redis-test]',
                   'File[/var/run/redis-test]',
                   'Group[redis-test]']
    )}
    it { should contain_disks__lv_mount('redis-test').with(
      :ensure  => 'absent',
      :folder  => '/var/lib/redis-test',
      :require => 'Service[redis-test]'
    )}
    it { should_not contain_class('redis_instance::base') }
    it { should have_selinux__seport_resource_count(0) }
    it { should contain_file('/var/log/redis-test').with(
      :ensure  => 'absent',
      :purge   => true,
      :recurse => true,
      :force   => true,
      :require => 'Service[redis-test]'
    )}
    it { should contain_file('/var/run/redis-test').with(
      :ensure  => 'absent',
      :purge   => true,
      :recurse => true,
      :force   => true,
      :require => 'Service[redis-test]'
    )}
    it { should contain_file('/etc/systemd/system/redis-test.service').with(
      :ensure  => 'absent',
      :purge   => true,
      :recurse => true,
      :force   => true,
      :require => 'Service[redis-test]'
    )}
    it { should contain_file('/etc/redis-test.conf').with(
      :ensure  => 'absent',
      :purge   => true,
      :recurse => true,
      :force   => true,
      :require => 'Service[redis-test]'
    )}
    it { should contain_service('redis-test').with(
      :ensure  => 'stopped',
      :enable  => false,
    )}
  end
end

