require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "PRAGMA table_info('#{table_name}')"

    columns = DB[:conn].execute(sql)
    column_names = columns.map {|column| column["name"]}
  end

  def initialize(hash={})
    hash.each do |k,v|
      self.send("#{k}=", v)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.select {|col_name| col_name!="id"}.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      if col_name != "id"
        values << self.send(col_name)
      end
    end
    "'" + values.join("', '") + "'"
  end

  def save
    sql = <<-SQL
    INSERT INTO #{table_name_for_insert}
    (#{col_names_for_insert}) VALUES (#{values_for_insert})
    SQL

    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]

  end

  def self.find_by_name(name)
    sql = <<-SQL
    SELECT * FROM #{table_name}
    WHERE name = ?
    SQL

    DB[:conn].execute(sql, name)
  end

  def self.find_by(hash={})
    key = hash.keys[0].to_s
    value = hash.values[0].to_s

    sql = <<-SQL
    SELECT * FROM #{table_name}
    WHERE #{key} = ?
    SQL
    
    DB[:conn].execute(sql, value)
  end







end
