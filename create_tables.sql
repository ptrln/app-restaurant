DROP TABLE IF EXISTS chefs;
DROP TABLE IF EXISTS restaurants;
DROP TABLE IF EXISTS chef_tenures;
DROP TABLE IF EXISTS critics;
DROP TABLE IF EXISTS restaurant_reviews;

CREATE TABLE chefs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  mentor_id INTEGER,
  FOREIGN KEY(mentor_id) REFERENCES chefs(id)
);

CREATE TABLE restaurants (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(255) NOT NULL,
  neighborhood VARCHAR(255) NOT NULL,
  cuisine VARCHAR(255) NOT NULL
);

CREATE TABLE chef_tenures (
  chef_id INTEGER NOT NULL,
  restaurant_id INTEGER NOT NULL,
  start_date TEXT NOT NULL,
  end_date TEXT,
  is_head_chef ENUM(1,0) NOT NULL,
  FOREIGN KEY(chef_id) REFERENCES chefs(id),
  FOREIGN KEY(restaurant_id) REFERENCES restaurants(id)
);

CREATE TABLE critics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  screen_name VARCHAR(255) NOT NULL
);

CREATE TABLE restaurant_reviews (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  text TEXT NOT NULL,
  critic_id INTEGER NOT NULL,
  restaurant_id INTEGER NOT NULL,
  score TINYINT NOT NULL,
  date TEXT NOT NULL DEFAULT (datetime('now','localtime')),
  FOREIGN KEY(critic_id) REFERENCES critics(id),
  FOREIGN KEY(restaurant_id) REFERENCES restaurants(id)
);

INSERT INTO chefs
     VALUES (1, "Peter", "Lin", NULL),
            (2, "Rex", "Hsieh", 1),
            (3, "Nick", "Hong", 2);

INSERT INTO restaurants
     VALUES (1, "Chipotle", "Market St", "Mexican"),
            (2, "Oasis", "Market St", "Mediterranean"),
            (3, "Oasha", "2nd St", "Thai");

INSERT INTO chef_tenures
     VALUES (1, 1, '2012-03-29', NULL, 1),
            (2, 2, '2013-03-11', '2013-03-12', 0),
            (2, 3, '2013-03-13', NULL, 1),
            (3, 3, '2013-04-01', NULL, 0);

INSERT INTO critics
     VALUES (1, "ruggeri"), (2, "rsepassi");

INSERT INTO restaurant_reviews
     VALUES (1, "Chipotle is the best restaurnt ever!", 1, 1, 20, '2013-03-13'),
            (2, "Oasha is pretty good.", 2, 3, 15, '2013-03-01');