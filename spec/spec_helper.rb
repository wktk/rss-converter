def fixture(path)
  File.open(File.join(File.dirname(__FILE__), 'fixtures', path))
end

require 'rack/test'
require 'rspec'

ENV['RACK_ENV'] = 'test'

require File.expand_path '../../app/app.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app
    described_class
  end
end

RSpec.configure do |config|
  config.include RSpecMixin
end
