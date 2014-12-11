require "guard/compat/test/helper"

RSpec.describe Guard::Zeus do
  before do
    allow(Guard::Compat::UI).to receive(:info)
  end

  describe '#initialize' do
    it "instantiates Runner with given options" do
      expect(Guard::Zeus::Runner).to receive(:new).with(:bundler => false)
      Guard::Zeus.new :bundler => false
    end
  end

  describe '.start' do
    it "calls Runner.kill_zeus and Runner.launch_zeus with 'Start'" do
      expect(subject.runner).to receive(:kill_zeus)
      expect(subject.runner).to receive(:launch_zeus).with('Start')
      subject.start
    end
  end

  describe '.reload' do
    it "calls Runner.kill_zeus and Runner.launch_zeus with 'Reload'" do
      expect(subject.runner).to receive(:kill_zeus)
      expect(subject.runner).to receive(:launch_zeus).with('Reload')
      subject.reload
    end
  end

  describe '.run_all' do
    it "calls Runner.run_all" do
      expect(subject.runner).to receive(:run_all)
      subject.run_all
    end
  end

  describe '.run_on_modifications' do
    it "calls Runner.run with file name" do
      expect(subject.runner).to receive(:run).with('file_name.rb')
      subject.run_on_modifications('file_name.rb')
    end

    it "calls Runner.run with paths" do
      expect(subject.runner).to receive(:run).with(['spec/controllers', 'spec/requests'])
      subject.run_on_modifications(['spec/controllers', 'spec/requests'])
    end
  end

  describe '.stop' do
    it 'calls Runner.kill_zeus' do
      expect(subject.runner).to receive(:kill_zeus)
      subject.stop
    end
  end

end
