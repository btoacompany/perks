#coding:utf-8
require 'yaml'

class Util
  def self.years
    year = Time.now.year
    return (1920..year).to_a
  end
end
