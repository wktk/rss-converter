require './spec/spec_helper'
require 'rack/lint'

describe RssConverter::App do
  describe "GET /" do
    it "should allow accessing the home page" do
      get '/'
      expect(last_response).to be_ok
    end

    it "renders a form that submits the converter parameters to /rss" do
      get '/'
      page = Nokogiri::HTML.parse(last_response.body)

      expect(page.at_css('form')['action']).to eq '/rss'
      expect(page.css('form input[name]').map { |i| i['name'] }).to eq RssConverter::ATTRIBUTES.map(&:to_s)
      expect(page.at_css('title').text).to eq 'RSS Converter'
    end
  end

  describe "GET /rss" do
    before do
      stub_page('http://example.com', fixture('news.html').read)
      freeze_time(Time.local(2020, 5, 2, 16, 16, 45))
    end

    it "converts the page with the given params" do
      get '/rss', url: 'http://example.com', index_selector: 'ul', article_selector: 'li',
                  link_selector: 'a', date_selector: '.date'

      expect(last_response).to be_ok
      expect(last_response.get_header('content-type')).to eq 'application/atom+xml'
      expect(last_response.body).to eq fixture('news.xml').read
    end

    it "returns a feed whose entries can be read back" do
      get '/rss', url: 'http://example.com', index_selector: 'ul', article_selector: 'li',
                  link_selector: 'a', date_selector: '.date'

      feed = RSS::Parser.parse(last_response.body, true)

      expect(feed.entries.map { |e| e.title.content }).to eq %w(
        猛暑日を記録しました あじさいが見頃です 桜が満開になりました 春一番を観測しました 初雪を観測しました
      )
    end

    it "accepts selectors that need URL encoding" do
      stub_page('http://example.com/complex?x=1&y=2', '<div id="n"><ul><li><a href="/1">one</a></li></ul></div>')

      get '/rss', url: 'http://example.com/complex?x=1&y=2', index_selector: 'div#n > ul',
                  article_selector: 'li:first-child', link_selector: 'a', date_selector: '.date'

      expect(last_response).to be_ok
      expect(RSS::Parser.parse(last_response.body, true).entries.size).to eq 1
    end
  end

  describe "Rack compliance" do
    def app
      Rack::Lint.new(RssConverter::App)
    end

    before { stub_page('http://example.com', fixture('news.html').read) }

    it "serves / and /rss as valid Rack responses" do
      get '/'
      expect(last_response).to be_ok

      get '/rss', url: 'http://example.com', index_selector: 'ul', article_selector: 'li',
                  link_selector: 'a', date_selector: '.date'
      expect(last_response).to be_ok
    end
  end
end
