#
# Cookbook Name:: imos_core
# Library:: groovy_helper
#
# Copyright 2015, IMOS
#
# All rights reserved - Do Not Redistribute
#

class Object
  def to_groovy
    "#{self}"
  end
end

class String
  def to_groovy
    "\"#{self}\""
  end
end

class Array
  def to_groovy
    "[\n#{map { |v| v.to_groovy }.join(", \n")}\n]"
  end
end

class Hash
  def to_groovy
    as_groovy = "[\n"

    as_groovy += map { |k, v|

      "#{k}: #{v.to_groovy}"
    }.join(",\n")

    as_groovy + "\n]"
  end
end

class GroovyIndenter
  def self.indent(text)
    indented_text = ''
    level = 0
    text.each_line do |line|

      if line.include? ']'
        level -= 1
      end

      (level * 2).times { indented_text += ' ' }
      indented_text += line

      if line.include? '['
        level += 1
      end
    end

    indented_text
  end
end
