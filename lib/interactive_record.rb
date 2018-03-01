require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  def initialize(attributes = {})
    attributes.each do |property, value|
      self.send("#{property}=",value)
    end #attributes
  end

  def col_names_for_insert
    columns = self.class.column_names
    columns_to_insert= columns.select {|col| col != "id"}
    columns_to_insert.join(", ")
  end

  def table_name_for_insert
    self.class.table_name
  end

  def save
    #save to dbt
    sql = "INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert}) VALUES (#{self.values_for_insert})"
    # puts "*************#{sql}"
    DB[:conn].execute(sql)
    #assign id
    @id = DB[:conn].execute("SELECT last_insert_rowID() from #{self.table_name_for_insert}")[0][0]
    # puts "******#{@id}"
    # puts "************"
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col|
      # puts "***********#{col}"
      # puts "***********#{send(col.to_sym)}"
      values << "'#{send(col.to_sym)}'" unless col=="id"# unless "#{send(col.to_sym).nil?}"
    end
    # puts "*********#{values}"
    values.join(", ")
  end

  def self.column_names
    sql = "PRAGMA table_info('#{self.table_name}')"
    pragma = DB[:conn].execute(sql)
    column_names_array=[]
    pragma.each do  |hash|
      column_names_array << hash["name"]
    end
    # puts "*********#{column_names_array}"
    column_names_array
  end

  def self.find_by(column_hash)
    sql = "SELECT * FROM #{self.table_name} WHERE #{column_hash.keys[0]} = '#{column_hash[column_hash.keys[0]]}'"
    # puts "********#{sql}"
    DB[:conn].execute(sql)

  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

  def self.table_name
    name  = self.to_s.downcase.pluralize
    # STDERR.puts "**************************#{self.to_s.downcase.pluralize}"
  end

  #MAKE THE  attr_accessor. the reson it runs is because its not in a method rather runs when class object created.
  # self.column_names.each do |col_name|
  # attr_accessor col_name.to_sym
  # end
  # self.column_names.each do |col_name|
  #   attr_accessor col_name.to_symh
  # end

end
