require 'spec_helper_acceptance'

describe 'basic octavia' do

  context 'default parameters' do

    it 'should work with no errors' do
      pp= <<-EOS
      include ::openstack_integration
      include ::openstack_integration::repos
      include ::openstack_integration::rabbitmq
      include ::openstack_integration::mysql
      include ::openstack_integration::keystone

      rabbitmq_user { 'octavia':
        admin    => true,
        password => 'an_even_bigger_secret',
        provider => 'rabbitmqctl',
        require  => Class['rabbitmq'],
      }

      rabbitmq_user_permissions { 'octavia@/':
        configure_permission => '.*',
        write_permission     => '.*',
        read_permission      => '.*',
        provider             => 'rabbitmqctl',
        require              => Class['rabbitmq'],
      }

      class { '::octavia::db::mysql':
        password => 'a_big_secret',
      }
      class { '::octavia::keystone::auth':
        password => 'a_big_secret',
      }

      # Octavia is not packaged on Ubuntu platform.
      if $::osfamily == 'RedHat' {
        class { '::octavia::db':
          database_connection => 'mysql+pymysql://octavia:a_big_secret@127.0.0.1/octavia?charset=utf8',
        }
        class { '::octavia::logging':
          debug => true,
        }
        class { '::octavia':
          rabbit_userid   => 'octavia',
          rabbit_password => 'an_even_bigger_secret',
          rabbit_host     => '127.0.0.1',
        }
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end
  end

end