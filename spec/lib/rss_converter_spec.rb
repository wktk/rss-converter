require './spec/spec_helper'

describe RssConverter do
  subject { RssConverter.new(**valid_arguments) }

  before do
    allow(URI).to receive(:open).with('http://example.com') { fixture('news.html') }
  end

  let(:valid_arguments) { {
    url: 'http://example.com',
    index_selector: 'ul',
    article_selector: 'li',
    link_selector: 'a',
    date_selector: '.date',
  } }

  describe '#initialize' do
    context 'when arguments are vaild' do
      it 'sets arguments to instance variables' do
        expect(subject.url).to eq 'http://example.com'
      end
    end

    context 'when arguments are not fulfilled' do
      subject { RssConverter.new(**valid_arguments.slice(:url)) }

      it { expect { subject }.to raise_error(ArgumentError) }
    end
  end

  describe '#html_document' do
    it 'parses HTML' do
      expect(subject.html_document).to be_a Nokogiri::HTML::Document
      expect(subject.html_document.to_s).to eq fixture('news.html').read
    end
  end

  describe '#index' do
    it 'selects index with index_selector' do
      expect(subject.index.to_s).to start_with '<ul>'
    end
  end

  describe '#articles' do
    it 'selects articles with article_selector' do
      subject.articles.each do |article|
        expect(article.to_s).to start_with '<li>'
      end
    end
  end

  describe '#entries' do
    it 'parses the document' do
      expect(subject.entries).to eq [
        { link: 'http://example.com/news/2020-07-01-1.html', title: '猛暑日を記録しました', updated: Date.new(2020, 7, 1) },
        { link: 'http://example.net/azisai.html', title: 'あじさいが見頃です', updated: Date.new(2020, 6, 21) },
        { link: 'http://example.com/news/2020-04-02-1.html', title: '桜が満開になりました', updated: Date.new(2020, 4, 2) },
        { link: 'http://example.com/news/2020-03-09-1.html', title: '春一番を観測しました', updated: Date.new(2020, 3, 9) },
        { link: 'http://example.com/news/2019-12-13-1.html', title: '初雪を観測しました', updated: Date.new(2019, 12, 13) },
      ]
    end
  end

  describe '#rss' do
    before { allow(Time).to receive(:now) { '2020-05-02T16:16:45+09:00' } }

    it 'generates RSS' do
      expect(subject.rss).to be_a RSS::Atom::Feed
      expect(subject.rss.to_s).to eq fixture('news.xml').read
    end
  end
end
