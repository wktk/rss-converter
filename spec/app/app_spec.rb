require './spec/spec_helper'

describe RssConverter::App do
  describe "GET /" do
    it "should allow accessing the home page" do
      get '/'
      expect(last_response).to be_ok
    end
  end

  describe "GET /rss" do
    let(:xml) { fixture('news.xml').read }

    before do
      allow_any_instance_of(RssConverter).to receive(:rss) { xml }
    end

    it "passes params to a RssConverter correctly" do
      expect(RssConverter).to receive(:from).with(
        "url" => "url",
        "index_selector" => "idx",
        "article_selector" => "atc",
        "link_selector" => "lnk",
      ).once.and_call_original

      get '/rss?url=url&index_selector=idx&article_selector=atc&link_selector=lnk'

      expect(last_response).to be_ok
      expect(last_response.get_header('content-type')).to eq 'application/rss+xml'
      expect(last_response.body).to eq xml
    end
  end
end
