require 'singleton'
require 'sqlite3'
require_relative 'base_model'

class Chef < Model
  attr_accessible :first_name, :last_name
  has_many(:proteges, "chefs", "mentor_id") { |c| Chef.parse(c) }
  belongs_to(:mentor, "chefs") { |c| Chef.parse(c) }

  def self.table_name
    'chefs'
  end

  def reviews

  end

  def co_workers

  end
end

class Restaurant < Model
  attr_accessible :name, :neighborhood, :cuisine
  has_many(:reviews, "restaurant_reviews", "restaurant_id") { |r| Review.parse(r) }

  def self.table_name
    'restaurants'
  end

  def average_review_score
    DB.get_first_value(<<-SQL, id)
      SELECT AVG(score)
        FROM restaurant_reviews
       WHERE restaurant_id = ?
    SQL
  end
end

class Critic < Model
  attr_accessible :screen_name
  has_many(:reviews, "restaurant_reviews", "critic_id") { |r| Review.parse(r) }

  def self.table_name
    'critics'
  end

  def average_review_score
    DB.get_first_value(<<-SQL, id)
      SELECT AVG(score)
        FROM restaurant_reviews
       WHERE critic_id = ?
    SQL
  end

  def unreviewed_restaurants
    DB.execute(<<-SQL, id).map { |r| Restaurant.parse(r) }
      SELECT *
        FROM restaurants
       WHERE id NOT IN (SELECT restaurant_id
                          FROM restaurant_reviews
                         WHERE critic_id = ?)
    SQL
  end
end

class Review < Model
  attr_accessible :text, :critic_id, :restaurant_id, :score, :date
  belongs_to(:critic, "critics") { |c| Critic.parse(c) }
  belongs_to(:restaurant, "restaurants") { |r| Restaurant.parse(r) }

  def self.table_name
    'restaurant_reviews'
  end

  def score=(value)
    raise "invalid score (must be between 1-20)" unless value.between?(1, 20)
    @score = value
  end
end

peter = Chef.find(1)
p peter
peter.first_name = "Pete"
peter.save
p Chef.find(1)
peter.first_name = "Peter"
peter.save

p Restaurant.by_neighborhood("Market St").first.average_review_score
p Critic.by_screen_name("ruggeri").first.unreviewed_restaurants