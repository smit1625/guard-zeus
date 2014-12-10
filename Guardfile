guard 'bundler' do
  watch('Gemfile')
  watch(%r{^.+\.gemspec$})
end

guard :rspec, cmd: "bundle exec rspec" do
  require "ostruct"

  rspec = OpenStruct.new
  rspec.spec_dir = "spec"
  rspec.spec = ->(m) { "#{rspec.spec_dir}/#{m}_spec.rb" }
  rspec.spec_helper = "#{rspec.spec_dir}/spec_helper.rb"

  # Ruby apps
  ruby = OpenStruct.new
  ruby.lib_files = %r{^(lib/.+)\.rb$}

  watch(%r{^#{rspec.spec_dir}/.+_spec\.rb$})
  watch(rspec.spec_helper)      { rspec.spec_dir }
  watch(ruby.lib_files)     { |m| rspec.spec.(m[1]) }
end

guard :rubocop do
  watch(%r{.+\.rb$})
  watch(%r{(?:.+/)?\.rubocop(?:_todo)?\.yml$}) { |m| File.dirname(m[0]) }
end
