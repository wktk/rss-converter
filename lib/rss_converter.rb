require 'nokogiri'
require 'open-uri'
require 'rss'
require 'wareki'

class RssConverter
  def initialize(url:, index_selector:, article_selector:, link_selector:, date_selector:)
    @url = url
    @index_selector = index_selector
    @article_selector = article_selector
    @link_selector = link_selector
    @date_selector = date_selector
  end
  attr_accessor :url, :index_selector, :article_selector, :link_selector, :date_selector

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
    articles.map do |article|
      link = article.css(link_selector).first
      href = link['href']
      href = URI.join(url, href).to_s unless href.start_with?('http')

      {
        link: href,
        title: link.text,
        updated: Date.parse(article.css(date_selector).text),
      }
    end
  end

  def rss
    RSS::Maker.make("atom") do |maker|
      maker.channel.author = "rss-converter"
      maker.channel.updated = Time.now.to_s
      maker.channel.about = url
      maker.channel.title = url

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
