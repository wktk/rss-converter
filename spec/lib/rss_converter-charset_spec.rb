require './spec/spec_helper'

describe 'RssConverter character encodings' do
  before { freeze_time(Time.local(2020, 5, 2, 16, 16, 45)) }

  # ㈱ ① ～ exist in Windows-31J and UTF-8 but not in EUC-JP, so EUC-JP gets
  # its own markup.
  let(:markup) do
    <<~HTML
      <ul>
        <li><a href='/a'>あじさいが見頃です</a><span class='d'>令和2年6月21日</span></li>
        <li><a href='/b'>㈱本店①～</a><span class='d'>2020/07/01</span></li>
      </ul>
    HTML
  end
  let(:euc_markup) { markup.sub('㈱本店①～', '本店') }

  def entries_from(body, content_type)
    stub_request(:get, 'http://example.com/').to_return(body: body, headers: { 'Content-Type' => content_type })
    RssConverter.new(
      url: 'http://example.com/', index_selector: 'ul', article_selector: 'li',
      link_selector: 'a', date_selector: '.d',
    ).entries
  end

  def expect_decoded(entries, second_title = '㈱本店①～')
    expect(entries.map { |e| e[:title] }).to eq ['あじさいが見頃です', second_title]
    expect(entries.map { |e| e[:updated] }).to eq [Time.local(2020, 6, 21, 0, 0, 1), Time.local(2020, 7, 1, 0, 0, 1)]
  end

  context 'when the encoding is declared in the HTTP header' do
    it('reads Shift_JIS') { expect_decoded entries_from(markup.encode('Windows-31J'), 'text/html; charset=Shift_JIS') }
    it('reads Windows-31J') { expect_decoded entries_from(markup.encode('Windows-31J'), 'text/html; charset=windows-31j') }
    it('reads x-sjis') { expect_decoded entries_from(markup.encode('Windows-31J'), 'text/html; charset=x-sjis') }
    it('reads EUC-JP') { expect_decoded entries_from(euc_markup.encode('EUC-JP'), 'text/html; charset=EUC-JP'), '本店' }
    it('reads UTF-8') { expect_decoded entries_from(markup, 'text/html; charset=UTF-8') }
    it('accepts quoted values') { expect_decoded entries_from(markup, 'text/html; charset="utf-8"') }
  end

  context 'when only the document declares the encoding' do
    it 'reads <meta charset>' do
      body = "<meta charset=\"Shift_JIS\">#{markup}".encode('Windows-31J')
      expect_decoded entries_from(body, 'text/html')
    end

    it 'reads <meta http-equiv>' do
      body = "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=shift_jis\">#{markup}".encode('Windows-31J')
      expect_decoded entries_from(body, 'text/html')
    end

    # Half-width katakana in Shift_JIS is also valid EUC-JP, so only the
    # declaration tells them apart.
    it 'reads half-width katakana declared by <meta>' do
      body = "<meta charset=\"Shift_JIS\"><ul><li><a href='/a'>ﾆｭｰｽ</a></li></ul>".encode('Windows-31J')

      expect(entries_from(body, 'text/html').first[:title]).to eq 'ﾆｭｰｽ'
    end

    it 'reads an unquoted <meta charset> in EUC-JP' do
      body = "<meta charset=euc-jp>#{euc_markup}".encode('EUC-JP')
      expect_decoded entries_from(body, 'text/html'), '本店'
    end
  end

  context 'when nothing declares the encoding' do
    it('guesses UTF-8') { expect_decoded entries_from(markup, 'text/html') }
    it('guesses Shift_JIS') { expect_decoded entries_from(markup.encode('Windows-31J'), 'text/html') }
    it('guesses EUC-JP') { expect_decoded entries_from(euc_markup.encode('EUC-JP'), 'text/html'), '本店' }

    it 'prefers EUC-JP when the bytes are also valid Shift_JIS' do
      body = "<ul><li><a href='/a'>ニュース</a></li></ul>".encode('EUC-JP')

      expect(entries_from(body, 'text/html').first[:title]).to eq 'ニュース'
    end
  end

  it('drops a UTF-8 BOM') { expect_decoded entries_from("﻿#{markup}", 'text/html') }

  context 'when declarations conflict or are unusable' do
    it 'prefers the HTTP header over <meta>' do
      expect_decoded entries_from("<meta charset=\"EUC-JP\">#{markup}", 'text/html; charset=utf-8')
    end

    it 'falls back to <meta> when the header names an unknown charset' do
      body = "<meta charset=\"Shift_JIS\">#{markup}".encode('Windows-31J')
      expect_decoded entries_from(body, 'text/html; charset=no-such-charset')
    end

    it 'does not fail on bytes that are invalid in the declared encoding' do
      body = "<ul><li><a href='/a'>ok\xFF\xFE</a></li></ul>".b

      expect(entries_from(body, 'text/html; charset=Shift_JIS').first[:title]).to start_with 'ok'
    end
  end
end
