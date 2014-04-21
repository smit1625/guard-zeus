source 'http://rubygems.org'

# Specify your gem's dependencies in guard-spin.gemspec
gemspec

gem "guard-bundler", "~> 2.0"
gem 'guard-rspec'

if RbConfig::CONFIG['target_os'] =~ /darwin/i
  gem 'growl', :require => false
end
if RbConfig::CONFIG['target_os'] =~ /linux/i
  gem 'libnotify', :require => false
end
