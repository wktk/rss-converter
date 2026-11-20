require 'nokogiri'
require 'rss'
require 'ssrf_filter'
require 'wareki'

class RssConverter
  ATTRIBUTES = %i(
    url
    index_selector
    article_selector
    link_selector
    date_selector
  ).freeze

  class << self
    def from(hash)
      new(**hash.slice(*ATTRIBUTES).map { |k, v| [k.to_sym, v] }.to_h)
    end
  end

  def initialize(url:, index_selector:, article_selector:, link_selector:, date_selector:)
    @url = url
    @index_selector = index_selector
    @article_selector = article_selector
    @link_selector = link_selector
    @date_selector = date_selector
  end
  attr_accessor(*ATTRIBUTES)

  def html_document
    @html_document ||= begin
      response = SsrfFilter.get(url, http_options: { open_timeout: 5, read_timeout: 10 })
      response.value
      Nokogiri::HTML.parse(decode(response))
    end
  end

  def index
    html_document.css(index_selector).first
  end

  def articles
    index.css(article_selector)
  end

  def entries
    count = Hash.new(0)
    articles.reverse.map do |article|
      link = if article['href']
        article
      else
        article.css(link_selector).find { |l| l['href'] && !l['href'].empty? }
      end
      next unless link
      href = link['href']
      href = URI.join(url, href).to_s unless href.start_with?('http')
      date = (Date.parse(article.css(date_selector).text) rescue Date.today)
      offset = count[date.to_s] += 1

      {
        link: href,
        title: link.text,
        updated: date.to_time + offset
      }
    end.compact.reverse
  end

  def title
    title = html_document.css('title').text
    title.empty? ? url : title
  end

  def rss
    RSS::Maker.make("atom") do |maker|
      maker.channel.author = "rss-converter"
      maker.channel.updated = Time.now.to_s
      maker.channel.about = url
      maker.channel.title = title

      entries.each do |entry|
        maker.items.new_item do |item|
          item.link = entry[:link]
          item.title = entry[:title]
          item.updated = entry[:updated].to_s
        end
      end
    end
  end

  private

  # libxml2 reads pages that declare nothing as ISO-8859-1, and its Shift_JIS
  # lacks the vendor characters (①, ㈱) that Japanese pages use.
  def decode(response)
    body = response.body.b
    declared = [response.type_params['charset'], body[/<meta\s[^>]*?charset\s*=\s*["']?([\w-]+)/i, 1]]
    encoding = declared.compact.filter_map { |name| find_encoding(name) }.first
    # EUC-JP before Shift_JIS: Shift_JIS text with kana is almost never valid
    # EUC-JP, while EUC-JP text often passes as Shift_JIS.
    encoding ||= [Encoding::UTF_8, Encoding::EUC_JP, Encoding::Windows_31J].find { |e| body.dup.force_encoding(e).valid_encoding? }
    body.force_encoding(encoding || Encoding::UTF_8).encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
  end

  def find_encoding(name)
    Encoding.find(name.match?(/\A(shift[_-]jis|x-sjis)\z/i) ? 'Windows-31J' : name)
  rescue ArgumentError
    nil
  end
end
