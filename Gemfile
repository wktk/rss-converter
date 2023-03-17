source 'https://rubygems.org'

ruby '3.2.1'

# HTTP Server
gem 'sinatra', '~> 3.0'
gem 'sinatra-contrib', '~> 3.0'
gem 'slim', '~> 5.0'

# HTML Parsing
gem 'rss', '~> 0.2.9'
gem 'nokogiri', '~> 1.13'
gem 'wareki', '~> 1.1'

group :production do
  gem 'puma', '~> 6.0'
end

group :test do
  gem 'rack-test', '~> 2.0'
  gem 'rspec', '~> 3.9'
  gem 'timecop', '~> 0.9.2'
end
