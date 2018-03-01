require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  # class names are singular and capitalized - this should land the correct word
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    # i guess this can interpolate variables since it never takes user input
    # are there any situations where this is dangerous?
    sql = "pragma table_info('#{table_name}')"

    # probs not since this is the singular execute and not batch
    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      # iterating through the array of hashes to pull name values out
      column_names << row["name"]
    end
    # removes nil values. what would cause nil values to turn up here
    column_names.compact
    # returns an array of column names.
  end

  puts "These are the column names: #{self.column_names}"

  def initialize(options={})
    options.each do |property, value|
      # what is going on here
      self.send("#{property}=", value)
      # addendum: see below, i figured it out eventually
    end
  end

  def save
    # Modular SQL statements. Cool
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    # pulls ID from most recent entry to update the ruby instance
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    # We wrap this so that we don't have to give access to this method outside the class.
    # still don't really grasp this but i think i get the general idea
    self.class.table_name
    # update: jk we do this because it's the instance that should be
    # responsible for handling this info, not the class
    # it's a software architecture thing
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
      # how would col_name ever be nil after we compacted it? is this just a failsafe?
      # NEVERMIND. Send is just a way to send a variable method name
      # In this case, we need to use send since we can't rely on what the col names are
      # and since we need to get at attr accessors for the col names
      # send col name here isn't returning a column name
      # it's returning the value we associated by using the column name as an attr_accessor
    end
    # makin it string friendly
    values.join(", ")
  end

  def col_names_for_insert
    # makin it string friendly
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def self.find_by_name(name)
    # return all from this table where name matches our query
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
    # i swear to god if i have to write this string one more time
  end

  def self.find_by(hash)
    sql = ""
    hash.each do |key, val|
      if val.kind_of?(String)
        sql = "SELECT * FROM #{self.table_name} WHERE #{key} = '#{val}'"
      else
        sql = "SELECT * FROM #{self.table_name} WHERE #{key} = #{val}"
      end
    end
    DB[:conn].execute(sql)
  end

end
