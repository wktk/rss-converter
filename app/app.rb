require 'sinatra/base'
require 'sinatra/reloader'
require 'slim'
require './lib/rss_converter.rb'

class RssConverter::App < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  get '/' do
    slim :index
  end

  get '/rss' do
    content_type 'application/rss+xml'
    RssConverter.from(params).rss.to_s
  end
end
