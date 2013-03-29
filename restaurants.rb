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
    DB.execute(<<-SQL, id).map { |r| Review.parse(r) }
      SELECT rr.*
        FROM restaurant_reviews rr
        JOIN chef_tenures ct
          ON ct.restaurant_id = rr.restaurant_id
       WHERE ct.chef_id = ?
         AND ct.is_head_chef = 1
         AND rr.date 
     BETWEEN ct.start_date 
         AND COALESCE(ct.end_date, date('now', 'localtime'))  -- gives today if no end date
    SQL
  end

  def co_workers
    DB.execute(<<-SQL, id, id).map { |c| Chef.parse(c) }
        SELECT chefs.*
          FROM chef_tenures me
          JOIN chef_tenures coworkers
            ON me.restaurant_id = coworkers.restaurant_id
          JOIN chefs
            ON chefs.id = coworkers.chef_id
         WHERE me.chef_id = ?
           AND coworkers.chef_id != ?
           AND (coworkers.start_date 
       BETWEEN me.start_date
           AND COALESCE(me.end_date, date('now', 'localtime'))
            OR me.start_date
       BETWEEN coworkers.start_date
           AND COALESCE(coworkers.end_date, date('now', 'localtime')))
    SQL
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
#p peter
#peter.first_name = "Pete"
#peter.save
#p Chef.find(1)
#peter.first_name = "Peter"
#peter.save

p peter.co_workers

# p Restaurant.by_neighborhood("Market St").first.average_review_score
# p Critic.by_screen_name("ruggeri").first.unreviewed_restaurants