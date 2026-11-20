require 'sinatra/base'
require 'sinatra/reloader'
require 'slim'
require './lib/rss_converter.rb'

class RssConverter::App < Sinatra::Base
  # Each platform exposes the deployed commit under its own name:
  # Render sets RENDER_GIT_COMMIT, Heroku buildpacks SOURCE_VERSION.
  COMMIT_ENV_KEYS = %w(RENDER_GIT_COMMIT SOURCE_VERSION GIT_COMMIT).freeze

  configure :development do
    register Sinatra::Reloader
  end

  helpers do
    def commit_sha
      ENV.values_at(*COMMIT_ENV_KEYS).find { |value| value && !value.empty? }&.slice(0, 7)
    end
  end

  get '/' do
    slim :index
  end

  get '/rss' do
    content_type 'application/atom+xml'
    RssConverter.from(params).rss.to_s
  end
end
