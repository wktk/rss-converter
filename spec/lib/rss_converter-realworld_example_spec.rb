require './spec/spec_helper'

describe 'RssConverter#rss (real world examples)' do
  subject { RssConverter.new(**args).rss.to_s }

  before do
    stub_page(args[:url], html.read)
    freeze_time(Time.local(2020, 5, 2, 16, 16, 16))
  end

  context 'Shibuya City' do
    let(:args) {
      {
        url: 'https://www.city.shibuya.tokyo.jp/news/index.html',
        index_selector: '.js-tabTarget.is-current',
        article_selector: 'li',
        link_selector: 'a',
        date_selector: '.date',
      }
    }
    let(:html) { fixture('realworld-shibuya.html') }

    it { is_expected.to eq fixture('realworld-shibuya.xml').read }
  end

  context 'MLIT JTSB' do
    let(:args) {
      {
        url: 'https://www.mlit.go.jp/jtsb/',
        index_selector: '.news',
        article_selector: 'dl',
        link_selector: 'a',
        date_selector: 'dt',
      }
    }
    let(:html) { fixture('realworld-mlit-jtsb.html') }

    it { is_expected.to eq fixture('realworld-mlit-jtsb.xml').read }
  end
end
