# Entry dates are built in the process's local zone, so the expected XML in
# the fixtures is only valid when the zone is pinned.
ENV['TZ'] = 'Asia/Tokyo'
ENV['RACK_ENV'] = 'test'

def fixture(path)
  File.open(File.join(File.dirname(__FILE__), 'fixtures', path))
end

require 'rack/test'
require 'rspec'
require 'webmock/rspec'

require File.expand_path '../../app/app.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app
    described_class
  end

  # Timecop 0.9.x calls Date._parse with three arguments, which wareki 2.x
  # rejects. RssConverter rescues that and falls back to today, so dates in
  # the output would silently be wrong.
  def freeze_time(time)
    allow(Time).to receive(:now).and_return(time)
    allow(Date).to receive(:today).and_return(time.to_date)
  end

  def stub_page(url, body, headers = {})
    stub_request(:get, url).to_return(
      body: body,
      headers: { 'Content-Type' => 'text/html; charset=utf-8' }.merge(headers),
    )
  end
end

RSpec.configure do |config|
  config.include RSpecMixin
  config.fail_if_no_examples = true

  # Host names resolve to a fixed public address so that specs never depend on
  # DNS. IP literals keep the real resolver.
  config.before do
    allow(Resolv).to receive(:getaddresses).and_wrap_original do |original, host|
      host.match?(/\A[\d.]+\z|:/) ? original.call(host) : ['93.184.216.34']
    end
  end
end
