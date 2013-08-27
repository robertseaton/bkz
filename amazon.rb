require 'nokogiri'
require 'open-uri'
require 'net/http'

def geturl(title)
  return "http://www.amazon.com/s/ref=nb_sb_noss_1?url=search-alias%3Dstripbooks&field-keywords=#{URI.encode(title)}"
end

def getresult(html, n)
  result_0 = html.css("div#result_#{n}").css(".productTitle")

  result = {
  :title => result_0.css(".productTitle").css("a")[0].text,
  :author => result_0.css(".productTitle").css(".ptBrand").text,
  :url => result_0.css(".productTitle").css("a")[0]["href"]
  }
  return result
end

def getratings(html)
  ratings = {
    :avg_rating => html.text.match("[1-5][.][0-5] out of 5 stars")[0].to_f,
    :ratings_count => html.text.match("[0-9]* customer review")[0].to_i
  }
  return ratings
rescue # In case there are no Amazon ratings...
  puts "Didn't find Amazon ratings."
  ratings = {
    :avg_rating => 0,
    :ratings_count => 0
  }
  return ratings
end

def amazon_search(title)
  url = geturl(title)
  html = Nokogiri::HTML(open(url))

  result = getresult(html, 0)
  # todo check if user's book

  html = Nokogiri::HTML(open(result[:url]))
  ratings = getratings(html)

  return ratings
end

def getrating(url)
end
