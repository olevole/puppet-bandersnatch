# Copyright 2015 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# = Class: bandersnatch
#
# Class to install common bandersnatch items.
#
class bandersnatch (
  $bandersnatch_source = 'pip',
) {

  if ! defined(Package['mercurial']) {
    package { 'mercurial':
      ensure => present,
    }
  }

  if ($bandersnatch_source == 'pip') {
    package { 'bandersnatch':
      # Bandersnatch v2 only supports python and starts at 3.5
      # We'll need to install python3 and upgrade to xenial before we can
      # use that.
      ensure   => '1.11',
      provider => openstack_pip,
    }
  } else {
    vcsrepo { '/opt/bandersnatch':
      ensure   => latest,
      provider => hg,
      source   => $bandersnatch_source,
    }

    exec { 'install_bandersnatch' :
      command     => 'pip install -U /opt/bandersnatch',
      path        => '/usr/local/bin:/usr/bin:/bin/',
      refreshonly => true,
      subscribe   => Vcsrepo['/opt/bandersnatch'],
      require     => [
        Class['pip'],
      ],
    }
  }

  file { '/var/log/bandersnatch':
    ensure => directory,
  }

  file { '/var/run/bandersnatch':
    ensure => directory,
  }

  include ::logrotate
  logrotate::file { 'bandersnatch':
    log     => '/var/log/bandersnatch/mirror.log',
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
  }

  file { '/usr/local/bin/run-bandersnatch':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/bandersnatch/run_bandersnatch.py',
  }
}
