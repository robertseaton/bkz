require 'rubygems'
require 'sequel'
require 'trollop'
require 'CSV'
require './goodreads.rb'

opts = Trollop::options do
  opt :title, "Title of book ", :type => :string
  opt :source, "Source of book recommendation", :type => :string
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

def create_books(db)
    db.create_table :books do
      primary_key :id
      String :title
      Integer :pages
      String :isbn
      Float :avg_rating
      Integer :ratings_count
      Integer :citations
      Date :published
      # recommended by
      # tags
    end
end

def create_authors(db)
  db.create_table :authors do
    primary_key :id
    String :author
    String :title
  end
end

def create_recommendations(db)
  db.create_table :recommendations do
    primary_key :id
    String :recommendation
    String :title
  end
end

def create_tags(db)
  db.create_table :tags do
    primary_key :id
    String :tag
    String :title
  end
end

def create_tables(db)
  create_books(db)
  create_authors(db)
  create_recommendations(db)
  create_tags(db)
end

def initdb(dbpath)
  db = getdb(dbpath)

  if initialize?(dbpath) then
    create_tables(db)
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
  scholar_results = CSV.parse(`python scholar.py --csv -c 1 "\"#{title}\""`, :col_sep => "|")
 
  if scholar_results[0][0].downcase.include?("cite") then
    error("scholar.py failed to parse citations for this entry. Please retry with a forced citation number via --citations. ")
  elsif title.downcase == scholar_results[0][0].downcase || askuser(scholar_results[0][0])
    citations = scholar_results[0][2].to_i
  else
    citations = 0
  end
  return citations
end

def add(title, citations_opt, db)
  goodreads_data = goodreads_search(title)

  if citations_opt.nil?
    citations = getcitations(title)
  else
    citations = citations_opt
  end
  db[:data].insert(:Title => title,
               :Citations => citations, 
               :Published => goodreads_data[:published],
               :"Goodreads Rating" => goodreads_data[:avg_rating], 
               :"Goodreads Reviews" => goodreads_data[:ratings_count])
  # db[:authors].insert(:title => title, :author => goodreads_data[:author])
end

def ratings_to_score(avg, count)
  return (count * (avg - 3))/2.0
end

def citations_to_score(citations)
  return citations * 4
end

def get_score(citations, avg_rating, ratings_count)
  return ratings_to_score(avg_rating, ratings_count) + citations_to_score(citations)
end

def print_books(db)
  output = []
  db[:books].each do |row|
    entry = []
    score = get_score(row[:citations], row[:avg_rating], row[:ratings_count])
    entry = {:title => row[:title], :score => score}
    output << entry
  end
  output = output.sort_by { |entry| entry[:score] }.reverse
  output.each do |entry|
    printf "%-100s %s\n", entry[:title], entry[:score]
  end
end

setauth('aPfKh3cgbelfhnkDgQLQ')

# create databse in memory
db = initdb("books.db")

books = db[:books]

p opts

# books.insert(:title => "Mindfulness, Bliss and Beyond")
if not opts[:print] then
  add(opts[:title], opts[:citations], db)
else
  print_books(db)
end

# todo:
# need to fix date published
# need to fix multi authors
# - a function that adds a comma separated list into a database
# the add() function is really ugly, I'd like to refactor it
# need to implement recommendations and recommendations count
# need to implement getting number of pages
# need to implement getting isbn
# need a switch to supply own database
