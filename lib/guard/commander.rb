module Guard
  module Commander
    def start(options={})
      puts "CUSTOM COMMANDER STARTING UP!"
      super
    end
  end
end
