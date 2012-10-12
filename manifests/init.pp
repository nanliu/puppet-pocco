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
  $rocco_package  = present,     #: rocco package installation
  $rocco_provider = gem,         #: rocco package provider gem
  $install_path   = '/opt/pocco' #: pocco installation path
) {

  # Pocco depends on rocco for the documentation parsing and highlighting.
  package { 'rocco':
    ensure   => $rocco_package,
    provider => $roccor_provider,
  }

  vcsrepo { '/opt/pocco':
    ensure => 'latest',
    source => 'git@github.com:nanliu/pocco.git',
  }

  # The exec command demonstrates pocco generating documentation.
  exec { 'update_pocco_docs':
    command     => '/opt/pocco/bin/pocco /opt/pocco',
    environment => ['RUBYOPT=rubygems', 'RUBYLIB=/opt/pocco/lib'],
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/pocco'],
  }
}
