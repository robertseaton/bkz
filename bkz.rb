require 'rubygems'
require 'sequel'
require 'trollop'
require 'csv'
require './goodreads.rb'
require './amazon.rb'
require './google-books.rb'
require './google.rb'

opts = Trollop::options do
  opt :title, "Title of book ", :type => :string
  opt :author, "Last name of author ", :type => :string
  opt :rating, "How many stars would you rate this title?", :type => :integer
  opt :recommendations, "How many people have recommended this book?", :type => :integer, :default => 0
  opt :citations, "Force citation count", :type => :integer
  opt :tags, "Tags for the book, e.g. a topic", :type => :string
  opt :print, "Print the database."
  opt :maintenance, "Run database maintenance."
end

def initialize?(dbpath)
  not File.exist?(dbpath)
end

def getdb(dbpath)
  Sequel.connect("sqlite://#{dbpath}")
end

def initdb(dbpath)
  db = getdb(dbpath)

  if initialize?(dbpath) then
    # create new table
  end
  return db
end

def askuser(title)
  puts "Is this the title of your book: #{title}? [y/n]"
  ans = gets 
  if ans.downcase == "y\n"
    return true
  else 
    return false
  end
end

def error(str)
  puts str
  exit
end

def getcitations(title)
  scholar_results = CSV::parse(`python2 scholar.py --csv -c 1 "#{title}"`, :col_sep => "|")
 
  if scholar_results[0][0].downcase.include?("cite") then
    error("scholar.py failed to parse citations for this entry. Please retry with a forced citation number via --citations. ")
  elsif title.downcase == scholar_results[0][0].downcase || askuser(scholar_results[0][0])
    citations = scholar_results[0][2].to_i
  else
    citations = 0
  end
  return citations
end

def gb_maintenance(db)
  db[:data].all { |record|
    info = GoogBooks::search(record[:Title])
    db[:data].where(:Title => record[:Title]).update(:Topic => info[:category])
    db[:data].where(:Title => record[:Title]).update(:GoogBooks_Rating => info[:avg_rating])
    db[:data].where(:Title => record[:Title]).update(:GoogBooks_Reviews => info[:ratings_count])
    db[:data].where(:Title => record[:Title]).update(:Pages => info[:page_count])
    db[:data].where(:Title => record[:Title]).update(:Author => info[:author])
  }
end

def am_maintenance(db)
    db[:data].all { |record|
    info = amazon_search(record[:Title], nil)
    db[:data].where(:Title => record[:Title]).update(:Price => info[:price])
  }
end

def g_maintenance(db)
  db[:data].all { |record|
    if db[:data].where(:Title => record[:Title]).first[:Google_Results].nil? ||
        db[:data].where(:Title => record[:Title]).first[:Google_Results_LW].nil? ||
        db[:data].where(:Title => record[:Title]).first[:Google_Results_HN].nil?
      count = Google::search(record[:Title], nil)
      count_lw = Google::search(record[:Title], "lesswrong.com")
      count_hn = Google::search(record[:Title], "news.ycombinator.com")
      db[:data].where(:Title => record[:Title]).update(:Google_Results => count)
      db[:data].where(:Title => record[:Title]).update(:Google_Results_LW => count_lw)
      db[:data].where(:Title => record[:Title]).update(:Google_Results_HN => count_hn)
    end
  }
end

def db_maintenance(db)
  # gb_maintenance(db)
  #am_maintenance(db)
  g_maintenance(db)
end

def add(title, author, citations_opt, recommendations, rating, db)
  goodreads_data = goodreads_search(title)
  amazon_data = amazon_search(title, author)
  googbooks_data = GoogBooks::search(title)
  google_results = Google::search(title, nil)
  google_results_lw = Google::search(title, "lesswrong.com")
  google_results_hn = Google::search(title, "news.ycombinator.com")

  if citations_opt.nil?
    citations = getcitations(title)
  else
    citations = citations_opt
  end
  db[:data].insert(:Title => title,
                   :Citations => citations, 
                   :Published => goodreads_data[:published],
                   :Goodreads_Rating => goodreads_data[:avg_rating], 
                   :Goodreads_Reviews => goodreads_data[:ratings_count],
                   :Amazon_Rating => amazon_data[:avg_rating],
                   :Amazon_Reviews => amazon_data[:ratings_count],
                   :Amazon_Book_Rank => amazon_data[:ranking],
                   :Price => amazon_data[:price],
                   :GoogBooks_Rating => googbooks_data[:avg_rating],
                   :GoogBooks_Reviews => googbooks_data[:ratings_count],
                   :Pages => googbooks_data[:page_count],
                   :Author => googbooks_data[:author],
                   :Rating => rating,
                   :Topic => googbooks_data[:category],
                   :Google_Results => google_results,
                   :Google_Results_LW => google_results_lw,
                   :Google_Results_HN => google_results_hn)
end
setauth('aPfKh3cgbelfhnkDgQLQ')

# create databse in memory
db = initdb("books.db")

if not opts[:maintenance] then
  add(opts[:title], opts[:author], opts[:citations], opts[:recommendations], opts[:rating], db)
else
  db_maintenance(db)
end

