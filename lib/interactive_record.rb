require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
 	
	def self.table_name
		self.to_s.downcase.pluralize
	end

	def self.column_names
		DB[:conn].results_as_hash = true
		sql = <<-SQL
			pragma table_info(#{table_name})
		SQL

		columns = DB[:conn].execute(sql)

		columns.map {|col| col['name']}.compact
	end

	def initialize(args={})
		puts args
		args.each {|key, value| self.send("#{key}=", value)}
	end

	def table_name_for_insert
		self.class.table_name
	end

	def col_names_for_insert
		self.class.column_names.delete_if {|col| col == 'id'}.join(', ')
	end

	def values_for_insert
		values = []
		self.class.column_names.each {|col| values << "'#{send(col)}'" if !send(col).nil?}
		values.join(', ')
	end

	def save
		sql = <<-SQL
			insert into #{table_name_for_insert} 
			(#{col_names_for_insert})
			values (#{values_for_insert})
		SQL

		DB[:conn].execute(sql)

		@id = DB[:conn].execute("select last_insert_rowid() from #{table_name_for_insert}")[0][0]
	end

	def self.find_by_name(name)
		sql = "select * from #{self.table_name} where name = '#{name}'"

		DB[:conn].execute(sql)
	end

	def self.find_by(hash)
		sql = "select * from #{self.table_name} where #{hash.keys[0]} = '#{hash[hash.keys[0]]}'"

		DB[:conn].execute(sql)
	end
end