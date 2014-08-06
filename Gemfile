source 'http://rubygems.org'

# Specify your gem's dependencies in guard-spin.gemspec
gemspec

gem 'guard-bundler', '~> 2.0'
gem 'guard-rspec', '~> 4.3.1'

if RbConfig::CONFIG['target_os'] =~ /darwin/i
  gem 'growl', :require => false
end
if RbConfig::CONFIG['target_os'] =~ /linux/i
  gem 'libnotify', '~> 0.8.3', :require => false
end
