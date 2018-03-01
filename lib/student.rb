require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'interactive_record.rb'

class Student < InteractiveRecord
  #get attr_accessor
  self.column_names.each do |property,value|
    # puts "#{column_names}"
    # puts "********#{property}"
    # puts "********#{value}"
    attr_accessor property.to_sym
  end
end
