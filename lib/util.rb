#coding:utf-8
require 'yaml'

class Util
  @category = YAML.load_file("config/categories.yml")

  def self.main_category
    return @category["main_category"]
  end

  def self.years
    year = Time.now.year
    return (1920..year).to_a
  end
end
