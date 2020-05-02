require 'nokogiri'
require 'open-uri'
require 'rss'

class RssConverter
  def initialize(url:, index_selector:, article_selector:, link_selector:)
    @url = url
    @index_selector = index_selector
    @article_selector = article_selector
    @link_selector = link_selector
  end
  attr_accessor :url, :index_selector, :article_selector, :link_selector

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

  def links
    articles.map { |article| article.css(link_selector).first }
  end

  def rss
    RSS::Maker.make("atom") do |maker|
      maker.channel.author = "rss-converter"
      maker.channel.updated = Time.now.to_s
      maker.channel.about = url
      maker.channel.title = url

      links.each do |link|
        href = link['href']
        href = URI.join(url, href).to_s unless href.start_with?('http')
        maker.items.new_item do |item|
          item.link = href
          item.title = link.text
          item.updated = Time.now.to_s
        end
      end
    end
  end
end
