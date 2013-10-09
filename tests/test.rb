require "../amazon.rb"
require "rubygems"
require "colorize"

def assert(truth, statement)
  if not truth then
    puts "FAILED: #{statement}".red
  end
end

def test_book(title, expected_rating, expected_ratings_count, expected_rank, expected_price)
  puts "#{title}".blue
  data = amazon_search(title, nil)

  got_rating = data[:avg_rating]
  got_ratings_count = data[:ratings_count]
  got_rank = data[:ranking]
  got_price = data[:price]
  abs_stars = expected_rating * expected_ratings_count
  got_abs_stars = got_rating * got_ratings_count
  
  assert(got_ratings_count >= expected_ratings_count, "# ratings should not decrease.")

  max_new_stars = (got_ratings_count - expected_ratings_count) * 5
  min_new_stars = (got_ratings_count - expected_ratings_count) * 1
  assert(got_abs_stars <= abs_stars + max_new_stars, "Max possible new stars exceeded.")
  assert(got_abs_stars >= abs_stars + min_new_stars, "Min possible new stars exceeded.")
  assert(got_price != nil, "No price found.")
  
  # Heuristics.
  max_plausible_new_ratings = 100
  num_new_ratings = got_ratings_count - expected_ratings_count
  max_dollar_change = 20
  dollar_change = (expected_price - got_price).abs
  assert(num_new_ratings <= max_plausible_new_ratings, "Implausible number of new reviews (#{num_new_ratings}).")
  assert(dollar_change <= max_dollar_change, "Large change in price (#{dollar_change}).")
end

test_book("The Origin of Consciousness in the Breakdown of the Bicameral Mind", 4.6, 194, 102435, 12.79)
test_book("Against Intellectual Monopoly", 3.7, 26, 754100, 16.38)
test_book("Indiscrete Thoughts", 4.8, 10, 595824, 32.76)
test_book("The Misbehavior of Markets", 3.9, 99, 39969, 12.88)
test_book("The Man Who Knew Infinity: A Life of the Genius Ramanujan", 4.6, 70, 75507, 11.59)
test_book("The Cuckoo's Egg: Tracking a Spy Through the Maze of Computer Espionage", 4.7, 240, 42728, 10.26)
test_book("Surely you're joking, Mr. Feynman", 4.6, 451, 2282, 11.56)
test_book("Programming the Universe: A Quantum Computer Scientist Takes on the Cosmos", 3.7, 45, 244181, 14.40)
test_book("Hackers & Painters: Big Ideas from the Computer Age", 4.1, 75, 189848, 12.28)
test_book("Blink: the power of thinking without thinking", 3.7, 1552, 209, 9.59)
test_book("A Mathematician's Lament: How School Cheats Us Out of Our Most Fascinating and Imaginative Art Form", 3.9, 36, 62951, 11.61)
test_book("Learning From Data", 4.8, 40, 531, 28.00)

