require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'debugger'

def geturl(title, author)

  mytitle = title.dup 
  
  if author != nil		
    mytitle = mytitle << "+by+" << author
  end

  mytitle = URI.encode("\"#{title}\"")

  return "http://www.amazon.com/s/ref=nb_sb_noss_1?url=search-alias%3Dstripbooks&field-keywords=#{mytitle}"
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

def getstars(html)
  stars = []

  for n in 0..4
    stars << html.css("div.histoCount.fl.gl10.ltgry.txtnormal")[n].text.to_i
  end

  debugger
  return stars
end

def getratings(html, title)

  rank = html.text.match("[,0-9]+ in Books").to_s
  rank = rank.delete('in Books').to_s
  rank = rank.delete(',').to_i
  
  ratings = {
    :avg_rating => html.text.match("[1-5][.][0-5] out of 5 stars")[0].to_f,
    :ratings_count => html.text.match("[,0-9]+ customer review")[0].delete(',').to_i,
    :stars => getstars(html),
    :ranking => rank,
    :price => getprice(html, title)
  }
  return ratings
rescue # In case there are no Amazon ratings...
  puts "Didn't find Amazon ratings."
  ratings = {
    :avg_rating => 0,
    :ratings_count => 0,
    :ranking => rank,
    :price => nil
  }
  return ratings
end

def getprice(html, title)
  price = html.css('.rentPrice').first.text.delete("\n $").to_f
  return price
rescue
  price = html.css('.priceLarge').first.text.delete("\n $").to_f
  return price
rescue
  price = nil
  return price
end

def amazon_search(title, author)
  url = geturl(title, author)
  html = Nokogiri::HTML(open(url))
  result = getresult(html, 0)
  # todo check if user's book

  html = Nokogiri::HTML(open(result[:url]))
  ratings = getratings(html, title)

  return ratings
end
