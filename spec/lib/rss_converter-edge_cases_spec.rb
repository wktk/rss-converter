require './spec/spec_helper'

describe 'RssConverter edge cases' do
  before { freeze_time(Time.local(2020, 5, 2, 16, 16, 45)) }

  def converter(html, **overrides)
    stub_page('http://example.com/', html)
    RssConverter.new(
      url: 'http://example.com/', index_selector: 'ul', article_selector: 'li',
      link_selector: 'a', date_selector: '.d', **overrides,
    )
  end

  def parsed_feed(converter)
    RSS::Parser.parse(converter.rss.to_s, true)
  end

  describe 'escaping' do
    let(:html) do
      <<~HTML
        <ul><li>
          <a href='/x?a=1&amp;b=2'>A &amp; B &lt;i&gt; "q" 😀</a>
          <span class='d'>2020-01-02</span>
        </li></ul>
      HTML
    end

    it 'keeps special characters intact through the Atom round trip' do
      entry = parsed_feed(converter(html)).entries.first

      expect(entry.title.content).to eq 'A & B <i> "q" 😀'
      expect(entry.link.href).to eq 'http://example.com/x?a=1&b=2'
    end

    it 'produces well-formed XML' do
      xml = Nokogiri::XML(converter(html).rss.to_s) { |config| config.strict }

      expect(xml.errors).to be_empty
    end
  end

  describe 'feed structure' do
    it 'generates a valid feed without entries when nothing matches the article selector' do
      feed = parsed_feed(converter('<ul></ul>'))

      expect(feed.entries).to be_empty
    end

    it 'uses the URL as the title when the page has no <title>' do
      expect(converter('<ul></ul>').title).to eq 'http://example.com/'
    end

    it 'uses the <title> of the page when present' do
      expect(converter('<title>News</title><ul></ul>').title).to eq 'News'
    end

    it 'skips articles without a usable link' do
      html = <<~HTML
        <ul>
          <li><a href=''>empty</a></li>
          <li>no link</li>
          <li><a href='/ok'>ok</a></li>
        </ul>
      HTML

      expect(converter(html).entries.map { |e| e[:title] }).to eq %w(ok)
    end
  end

  describe 'selectors' do
    it 'uses the article itself as the link when it has an href' do
      html = "<ul><li><a href='/a'>A</a></li><li><a href='/b'>B</a></li></ul>"
      entries = converter(html, article_selector: 'a').entries

      expect(entries.map { |e| e[:link] }).to eq %w(http://example.com/a http://example.com/b)
    end

    it 'supports compound CSS selectors' do
      html = <<~HTML
        <div id="news"><ul>
          <li class="item"><a href="/1">one</a></li>
          <li class="item"><a href="/2">two</a></li>
          <li class="item"><a href="/3">three</a></li>
        </ul></div>
        <div id="other"><ul><li class="item"><a href="/x">other</a></li></ul></div>
      HTML
      entries = converter(html, index_selector: 'div#news > ul', article_selector: 'li.item:nth-child(odd)').entries

      expect(entries.map { |e| e[:title] }).to eq %w(one three)
    end

    it 'resolves relative, root-relative and protocol-relative links against the URL' do
      html = <<~HTML
        <ul>
          <li><a href='page.html'>relative</a></li>
          <li><a href='/root.html'>root</a></li>
          <li><a href='//cdn.example.net/p.html'>protocol</a></li>
          <li><a href='https://other.example.org/abs.html'>absolute</a></li>
        </ul>
      HTML

      expect(converter(html).entries.map { |e| e[:link] }).to eq %w(
        http://example.com/page.html
        http://example.com/root.html
        http://cdn.example.net/p.html
        https://other.example.org/abs.html
      )
    end
  end
end
