require 'rubygems'
require 'sequel'
require 'trollop'
require 'csv'
require './goodreads.rb'
require './amazon.rb'

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
  scholar_results = CSV::parse(`python2 scholar.py --csv -c 1 "\"#{title}\""`, :col_sep => "|")
 
  if scholar_results[0][0].downcase.include?("cite") then
    error("scholar.py failed to parse citations for this entry. Please retry with a forced citation number via --citations. ")
  elsif title.downcase == scholar_results[0][0].downcase || askuser(scholar_results[0][0])
    citations = scholar_results[0][2].to_i
  else
    citations = 0
  end
  return citations
end

def update_dates(db)
  db[:data].all { |record|
    p record[:Title]
    if record[:Title] == "Value Focused Thinking: A Path to Creative Decision Making" ||
        record[:Title] == "Human inference: Strategies and shortcomings of social judgment" ||
        record[:Title] == "Japaneses Death Poems" ||
        record[:Title] == "Heuristics and Biases: The Psychology of Human Judgment" ||
        record[:Title] == "Wherever You Go That's Where You Are" ||
        record[:Title] == "Straight choices: the psychology of judgment and decision" ||
        record[:Title] == "The Enjoyment of Math"
      next
    end
    goodreads_data = goodreads_search(record[:Title])
    p goodreads_data[:published]
    db[:data].where(:Title => record[:Title]).update(:Published => goodreads_data[:published])
    p record
    if not (record[:Goodreads_Rating].to_f == goodreads_data[:avg_rating].to_f && record[:Goodreads_Reviews].to_f == goodreads_data[:ratings_count].to_f)
      print "Error in #{record[:Title]}.\n"
      print "Expected rating #{record[:Goodreads_Rating]}, got #{goodreads_data[:avg_rating]}.\n"
      print "Expected review count #{record[:Goodreads_Reviews]}, got #{goodreads_data[:ratings_count]}.\n\n"
    end }
end

def add(title, citations_opt, db)
  goodreads_data = goodreads_search(title)
  amazon_data = amazon_search(title)

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
                   :Amazon_Reviews => amazon_data[:ratings_count])
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

setauth('aPfKh3cgbelfhnkDgQLQ')

# create databse in memory
db = initdb("books.db")

p opts

# books.insert(:title => "Mindfulness, Bliss and Beyond")
if not opts[:print] then
  add(opts[:title], opts[:citations], db)
else
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
