require_relative "../config/environment.rb"
require 'active_support/inflector'
require "pry"
class InteractiveRecord
  def initialize(info_hash = {})
    info_hash.each do |col, val|
      self.send("#{col}=",val)
    end
  end

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    sql = "PRAGMA table_info('#{self.table_name}')"
    cols_hash = DB[:conn].execute(sql)
    cols_hash.map{|col_info| col_info["name"]}.compact
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    cols = self.class.column_names.delete_if{|col| col == "id"}.join(", ")
  end

  def values_for_insert
    "'" + self.class.column_names.collect{|col| send(col)}.compact.join("', '") + "'"
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = "SELECT *
    FROM #{self.table_name}
    WHERE name = ?"
    DB[:conn].execute(sql, name)
  end

  def self.find_by(attr)
    col = attr.keys[0].to_s
    val = attr.values
    sql = "SELECT *
    FROM #{self.table_name}
    WHERE #{col} = ?"
    DB[:conn].execute(sql, val)
  end


end
