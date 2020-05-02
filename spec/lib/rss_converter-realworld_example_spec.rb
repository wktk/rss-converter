require './spec/spec_helper'

require './lib/rss_converter'

describe 'RssConverter#rss (real world examples)' do
  subject { RssConverter.new(**args).rss.to_s }

  before do
    allow(URI).to receive(:open).with(args[:url]) { html.dup.tap { |f| f.pos = 0 } }
    allow(Time).to receive(:now) { '2020-05-02T16:16:16+09:00' }
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
