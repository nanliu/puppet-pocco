# __Pocco__ is derived from [Rocco](http://rtomayko.github.com/rocco/), the
# literate-programming-style documentation generator.
#
# Pocco reads Puppet manifests from puppet modules and produces annotated
# source documentation in HTML format in the module docs directory.
#
# WARNING: install pygments to process highlighting locally, otherwise the
# manifests are uploaded to
# [http://pygments.appspot.com](http://pygments.appspot.com) for processing.
#
# Pocco has some puppet specific functionality:
#
# * generate a header for class/define.
# * parse class/define parameter for defaults and comments.
# * import the corresponding manifests from the test directory as usage
# example.
#
class pocco (
  $ensure       = present,     #: rocco package installation
  $provider     = gem,         #: rocco package provider gem
  $install_path = '/opt/pocco' #: pocco installation path
) {

  # There's only one line requiring rake so might refactor away this requirement later.
  package { 'rake':
    ensure   => $ensure,
    provider => $provider,
  } ->

  # Pocco depends on rocco for the documentation parsing and highlighting.
  #
  # * redcarpet 2.2.1 is broken on Ubuntu 12.04: [#166](https://github.com/vmg/redcarpet/pull/166).
  # * redcarpet 2.2.0 triggers a bug in rocco: [#69](https://github.com/rtomayko/rocco/issues/69)
  package { 'fl-rocco':
    ensure   => $ensure,
    provider => $provider,
  } ->

  package { 'rocco':
    ensure   => $ensure,
    provider => $provider,
  } ->

  vcsrepo { '/opt/pocco':
    ensure   => latest,
    source   => 'https://github.com/nanliu/puppet-pocco.git',
    provider => 'git',
  }

  # The exec command demonstrates pocco generating documentation.
  exec { 'update_pocco_docs':
    command     => '/opt/pocco/bin/pocco /opt/pocco',
    environment => ['RUBYOPT=rubygems', 'RUBYLIB=/opt/pocco/lib'],
    logoutput   => on_failure,
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/pocco'],
  }
}
