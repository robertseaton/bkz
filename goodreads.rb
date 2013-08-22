require 'nokogiri'
require 'open-uri'

# set the authorization key
def setauth(key)
  $auth = key
end

# ask the user if this is the right book
def correct_book?(title, author)
  ans = nil

  while ans != "y" && ans != "n"
    puts "Title: #{title} Author: #{author} Is this your book? [y/n]:"
    gets ans

    if ans == "n"
      raise "Wrong book."
    end
  end
end

# get the books ISBN
def goodreads_search(title)
  title = URI.encode(title)
  xml = Nokogiri::XML(open("http://www.goodreads.com/search.xml?key=#{$auth}&q=#{title}"))
  book_info = {
    :author => xml.css("name").first.children.to_s, 
    :title => xml.css("title").first.children.to_s,
    :avg_rating => xml.css("average_rating").first.children.to_s.to_f,
    :ratings_count => xml.css("ratings_count").first.children.to_s.to_i,
    :published => xml.css("original_publication_year").first.children.to_s.to_i
  }

rescue
  puts "Warning: Goodreads data missing."
  book_info = {
    :avg_rating => 0,
    :ratings_count => 0,
  }
  # correct_book?(book_info[:title], book_info[:author])
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
