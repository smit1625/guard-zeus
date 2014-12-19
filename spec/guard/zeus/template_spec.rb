require 'guard/compat/test/template'

require 'guard/zeus'

RSpec.describe Guard::Zeus do
  describe 'template' do
    subject { Guard::Compat::Test::Template.new(described_class) }

    it 'works' do
      expect(subject.changed('spec/lib/foo_spec.rb')).to eq(%w(spec/lib/foo_spec.rb))
      expect(subject.changed('spec/spec_helper.rb')).to eq(%w(spec))
      expect(subject.changed('lib/foo.rb')).to eq(%w(spec/lib/foo_spec.rb))
      expect(subject.changed('app/foo.rb')).to eq(%w(spec/foo_spec.rb))
      expect(subject.changed('app/layouts/foo.slim')).to eq(%w(spec/layouts/foo.slim_spec.rb))

      expect(subject.changed('app/controllers/foo_controller.rb')).to match_array(
        %w(
          spec/controllers/foo_controller_spec.rb
          spec/routing/foo_routing_spec.rb
          spec/acceptance/foo_spec.rb
        )
      )
    end
  end
end
