require 'googlebooks'

class GoogBooks
  def self.nilcheck(checkme, default)
    if checkme.nil? || checkme == ""
      return default
    else
      return checkme
    end
  end
  
  def self.search(title)
    first_book = GoogleBooks.search(title, {:api_key => "AIzaSyB4h61e12sPWLea2eSovdLqzfUNh-RI_Ns"}, "24.14.247.168").first
    
    category = nilcheck(first_book.categories, "Uncategorized")
    author = nilcheck(first_book.authors, "Unknown")
    avg_rating = nilcheck(first_book.average_rating, 0)
    ratings_count = nilcheck(first_book.ratings_count, 0)
    
    info = {
      :category => category,
      :author => author,
      :avg_rating => avg_rating,
      :ratings_count => ratings_count,
      :page_count => first_book.page_count,
      :date => first_book.published_date
    }
    return info
  end
end
