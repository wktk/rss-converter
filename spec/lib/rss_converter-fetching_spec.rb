require './spec/spec_helper'

describe 'RssConverter fetching pages' do
  def converter_for(url)
    RssConverter.new(
      url: url, index_selector: 'ul', article_selector: 'li',
      link_selector: 'a', date_selector: '.d',
    )
  end

  def html_document_of(url)
    converter_for(url).html_document
  end

  it 'requests the page once per conversion' do
    stub_page('http://example.com/', "<title>t</title><ul><li><a href='/a'>a</a></li></ul>")

    converter_for('http://example.com/').rss

    expect(a_request(:get, 'http://example.com/')).to have_been_made.once
  end

  it 'refuses local files' do
    expect { html_document_of('/etc/hosts') }.to raise_error(SsrfFilter::Error)
    expect { html_document_of('file:///etc/hosts') }.to raise_error(SsrfFilter::Error)
  end

  ['http://127.0.0.1:9292/', 'http://169.254.169.254/latest/meta-data/', 'http://[::1]/'].each do |url|
    it "refuses #{url} without sending a request" do
      expect { html_document_of(url) }.to raise_error(SsrfFilter::PrivateIPAddress)
      expect(a_request(:any, /.*/)).not_to have_been_made
    end
  end

  it 'refuses a name that resolves to a private address' do
    allow(Resolv).to receive(:getaddresses).with('internal.example.com').and_return(['10.0.0.8'])

    expect { html_document_of('http://internal.example.com/') }.to raise_error(SsrfFilter::PrivateIPAddress)
  end

  it 'refuses a redirect to a private address' do
    stub_request(:get, 'http://example.com/').to_return(status: 302, headers: { 'Location' => 'http://169.254.169.254/latest/meta-data/' })

    expect { html_document_of('http://example.com/') }.to raise_error(SsrfFilter::PrivateIPAddress)
    expect(a_request(:get, /169\.254/)).not_to have_been_made
  end

  it 'follows a redirect to a public host' do
    stub_request(:get, 'http://example.com/old').to_return(status: 301, headers: { 'Location' => 'https://example.net/new' })
    stub_page('https://example.net/new', '<title>moved</title>')

    expect(html_document_of('http://example.com/old').title).to eq 'moved'
  end

  it 'fails on error responses' do
    stub_request(:get, 'http://example.com/').to_return(status: 404)

    expect { html_document_of('http://example.com/') }.to raise_error(Net::HTTPClientException)
  end
end
