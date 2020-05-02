require 'sinatra/base'
require 'slim'
require './lib/rss_converter.rb'

class App < Sinatra::Base
  get '/' do
    slim :index
  end

  get '/rss' do
    args = params.slice(*%i(url index_selector article_selector link_selector date_selector))
    converter = RssConverter.new(**args.map { |k, v| [k.to_sym, v] }.to_h)

    content_type 'application/atom+xml'
    converter.rss.to_s
  end
end
