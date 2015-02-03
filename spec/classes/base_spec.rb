require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe 'redis_instance::base', :type => 'class' do
  context 'with default params' do
    it { should contain_package('redis').with(
      :ensure => 'present'
    ) }
    it { should contain_selinux__policy('redis_instance').with(
      :fc_file   => true,
      :te_source => 'puppet:///modules/redis_instance/selinux_policy/redis_instance.te',
      :fc_source => 'puppet:///modules/redis_instance/selinux_policy/redis_instance.fc'
    )}
  end
end

