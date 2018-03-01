require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    sql = "PRAGMA table_info('#{table_name}')"
    table_info = DB[:conn].execute(sql)
    column_names = []

    table_info.each do |column|
      column_names << column["name"]
    end

    column_names.compact
  end

  def self.set_attributes
    self.column_names.each {|attribute| attr_accessor(attribute.to_sym)}
  end

  def initialize(attributes = nil)
    if attributes
      attributes.each do |k,v|
        self.send("#{k}=", v)
      end
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    result = self.class.column_names
    result.delete("id")
    result.join(", ") # ?????????
  end

  def values_for_insert
    self.class.column_names.map do |col|
      "'#{send(col)}'" if send(col)
    end.compact.join(", ")
  end

  def save
    DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})")
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    self.find_by(name: name)
  end

  def self.find_by(attribute)
    key = attribute.keys.first
    value = attribute[key]
    sql = "SELECT * FROM #{table_name} WHERE #{key} = '#{value}'"
    DB[:conn].execute(sql)
  end

end
