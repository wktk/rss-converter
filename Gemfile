source 'https://rubygems.org'

ruby '4.0.10'

# HTTP Server
gem 'sinatra', '~> 4.0'
gem 'sinatra-contrib', '~> 4.0'
gem 'slim', '~> 5.0'

# HTML Parsing
gem 'rss', '~> 0.3.0'
gem 'nokogiri', '~> 1.13'
gem 'wareki', '~> 2.1'

# HTTP Client
gem 'ssrf_filter', '~> 1.6'

group :production do
  gem 'puma', '~> 8.0'
end

group :test do
  gem 'rack-test', '~> 2.0'
  gem 'rspec', '~> 3.9'
  gem 'webmock', '~> 3.0'
end
