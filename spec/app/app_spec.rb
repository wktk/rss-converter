require './spec/spec_helper'

describe RssConverter::App do
  describe "GET /" do
    it "should allow accessing the home page" do
      get '/'
      expect(last_response).to be_ok
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
  end
end
