require 'nokogiri'
require 'open-uri'
require 'rss'
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
    html = URI.open(url).read
    Nokogiri::HTML.parse(html)
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
end
