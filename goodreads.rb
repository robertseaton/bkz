require 'nokogiri'
require 'open-uri'

# set the authorization key
def setauth(key)
  $auth = key
end

# get the books ISBN
def goodreads_search(title)
  title = URI.encode(title)
  xml = Nokogiri::XML(open("http://www.goodreads.com/search.xml?key=#{$auth}&q=#{title}"))
  puts xml
  book_info = {
    :author => xml.css("name").first.children.to_s, 
    :title => xml.css("title").first.children.to_s,
    :avg_rating => xml.css("average_rating").first.children.to_s.to_f,
    :ratings_count => xml.css("ratings_count").first.children.to_s.to_i,
    :published => xml.css("original_publication_year").first.children.to_s.to_i}
end

# get the books reviews
def getreviews(isbn)
end

# get the average rating of the book
def getavg(reviews)
end

# get the number of ratings
def getnum(reviews)
end
