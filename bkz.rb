require 'rubygems'
require 'sequel'
require 'trollop'
require 'csv'
require './goodreads.rb'
require './amazon.rb'

opts = Trollop::options do
  opt :title, "Title of book ", :type => :string
	opt :author, "Last name of author ", :type => :string
  opt :rating, "How many stars would you rate this title?", :type => :integer
  opt :recommendations, "How many people have recommended this book?", :type => :integer, :default => 0
  opt :citations, "Force citation count", :type => :integer
  opt :tags, "Tags for the book, e.g. a topic", :type => :string
  opt :print, "Print the database."
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

def add(title, author, citations_opt, recommendations, rating, db)
  goodreads_data = goodreads_search(title)
	#TODO check
  amazon_data = amazon_search(title, author)

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
                   :Rating => rating)
end
setauth('aPfKh3cgbelfhnkDgQLQ')

# create databse in memory
db = initdb("books.db")

if not opts[:print] then
  add(opts[:title], opts[:author], opts[:citations], opts[:recommendations], opts[:rating], db)
else
end

