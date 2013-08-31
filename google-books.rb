require 'open-uri'
require 'json'

def geturl(title)
  title = URI.encode(title)
  return "https://www.googleapis.com/books/v1/volumes?q=#{title}"
end

def googbooks_search(title)
  url = geturl(title)
  json = JSON.parse(open(url).read)
  categories = json["items"][0]["volumeInfo"]["categories"][0]
end
