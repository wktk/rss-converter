require './spec/spec_helper'

describe 'RssConverter date parsing' do
  let(:today) { Time.local(2020, 5, 2, 16, 16, 45) }

  before { freeze_time(today) }

  def updated_for(text)
    stub_page('http://example.com/', "<ul><li><a href='/x'>t</a><span class='d'>#{text}</span></li></ul>")
    RssConverter.new(
      url: 'http://example.com/', index_selector: 'ul', article_selector: 'li',
      link_selector: 'a', date_selector: '.d',
    ).entries.first[:updated]
  end

  {
    '平成31年4月30日' => [2019, 4, 30],
    '令和元年5月1日' => [2019, 5, 1],
    '令和2年4月13日' => [2020, 4, 13],
    'R2.4.1' => [2020, 4, 1],
    'H30.1.2' => [2018, 1, 2],
    '二〇二〇年四月二日' => [2020, 4, 2],
    '２０２０年４月２日' => [2020, 4, 2],
    '2020年3月9日' => [2020, 3, 9],
    '2020/07/01' => [2020, 7, 1],
    '2020-05-21' => [2020, 5, 21],
    '20-06-21' => [2020, 6, 21],
    '4月28日' => [2020, 4, 28],
  }.each do |text, (y, m, d)|
    it "parses #{text} as #{y}-#{m}-#{d}" do
      expect(updated_for(text)).to eq Time.local(y, m, d, 0, 0, 1)
    end
  end

  ['', 'not a date', '近日公開'].each do |text|
    it "falls back to today for #{text.inspect}" do
      expect(updated_for(text)).to eq Time.local(2020, 5, 2, 0, 0, 1)
    end
  end

  it 'distinguishes entries that share a date by one second each, keeping page order' do
    html = <<~HTML
      <ul>
        <li><a href='/1'>first</a><span class='d'>2020-01-02</span></li>
        <li><a href='/2'>second</a><span class='d'>2020-01-02</span></li>
        <li><a href='/3'>third</a><span class='d'>2020-01-02</span></li>
      </ul>
    HTML
    stub_page('http://example.com/', html)
    entries = RssConverter.new(
      url: 'http://example.com/', index_selector: 'ul', article_selector: 'li',
      link_selector: 'a', date_selector: '.d',
    ).entries

    expect(entries.map { |e| e[:title] }).to eq %w(first second third)
    expect(entries.map { |e| e[:updated].sec }).to eq [3, 2, 1]
  end
end
