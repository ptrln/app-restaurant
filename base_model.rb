class Model

  class RestaurantDB < SQLite3::Database
    include Singleton

    def initialize
      super("restaurants.db")
      self.results_as_hash = true
      self.type_translation = true
    end
  end

  attr_reader :id
  DB = RestaurantDB.instance
  @column_names = Hash.new { Array.new }
  
  def initialize(id = nil)
    @id = id
  end

  def self.table_name
    raise NotImplementedError
  end

  def self.find(id)
    sql = <<-SQL
         SELECT *
           FROM #{self.table_name}
          WHERE id = #{id}
    SQL
    self.parse(DB.execute(sql).first)
  end

  def self.all
    sql = <<-SQL
        SELECT * FROM #{self.table_name}
    SQL
    DB.execute(sql).map { |h| self.parse(h) }
  end

  def self.column_names
    @column_names || []
  end

  def self.add_column_name(name)
    @column_names.nil? ? @column_names = [name] : @column_names << name
  end

  def self.parse(hash)
    return nil if hash.nil?
    obj = self.new(hash['id'])
    hash.each do |column_name, value|
      if obj.class.column_names.include?(column_name.to_sym)
        obj.send("#{column_name}=", value)
      end
    end
    obj
   end

  def save 
    id.nil? ? insert : update
  end

  protected
  def insert
    col_names = self.class.column_names.map { |col| "#{col}"}.join(', ')
    values = self.class.column_names.map { |col| self.send(col) }
    question_marks = (['?'] * values.count).join(', ')
    
    sql = <<-SQL
      INSERT INTO #{self.class.table_name} (#{col_names})
      VALUES (#{question_marks})
    SQL

    DB.execute(sql, *values)
    @id = DB.last_insert_row_id
  end

  def update
    columns = self.class.column_names.map { |col| "#{col} = ?"}.join(', ')
    values = self.class.column_names.map { |col| self.send(col) }
    sql = <<-SQL
      UPDATE #{self.class.table_name}
      SET    #{columns}
      WHERE  id = ?
    SQL
    DB.execute(sql, *values, id)
  end

  def self.attr_accessible(*col_names)
    col_names.each do |column_name|
      add_column_name(column_name)
      define_instance_variables(column_name)
      define_find_by_column_names(column_name)
    end
  end

  def self.define_find_by_column_names(column_name)
    self.class.send(:define_method, "by_#{column_name}") do |value|
      raise NoMethodError unless @column_names.include?(column_name)
      sql = <<-SQL
        SELECT *
          FROM #{self.table_name}
         WHERE #{column_name} = ?
      SQL
      DB.execute(sql, value).map { |h| self.parse(h) }
    end
  end

  def self.define_instance_variables(column_name)
    self.send(:define_method, "#{column_name}") do
      self.instance_variable_get("@#{column_name}")
    end
    self.send(:define_method, "#{column_name}=") do |value|
      self.instance_variable_set("@#{column_name}", value)
    end
  end

  def self.has_many(other, table_name, my_key, &proc)
    define_get_many(other, table_name, my_key, &proc)
    define_num_many(other, table_name, my_key)
  end

  def self.define_get_many(other, table_name, my_key, &proc)
    body = Proc.new do
      return [] unless self.send(:id)
      sql = <<-SQL
        SELECT *
          FROM #{table_name}
         WHERE #{my_key} = ?
      SQL
      DB.execute(sql, self.send(:id)).map { |h| proc.call(h) }
    end
    self.send(:define_method, other, &body)
  end

  def self.define_num_many(other, table_name, my_key)
    body = Proc.new do
      return [] unless self.send(:id)
      sql = <<-SQL
        SELECT COUNT(*)
          FROM #{table_name}
         WHERE #{my_key} = ?
      SQL
      DB.get_first_value(sql, self.send(:id))
    end
    self.send(:define_method, "num_#{other}", &body)
  end

  def self.belongs_to(other, table, &proc)
    attr_accessible("#{other}_id".to_sym)
    body = Proc.new do
      return nil unless self.send("#{other}_id")
      sql = <<-SQL
        SELECT *
          FROM #{table}
         WHERE id = ?
      SQL
      proc.call(DB.get_first_row(sql, self.send("#{other}_id")))
    end
    self.send(:define_method, other, &body)
  end

end