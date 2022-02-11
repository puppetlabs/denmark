# frozen_string_literal: true
require 'paint'
require 'paint/shortcuts'

class Array
  def percent_of(digits = nil)
    raise "Select the items you want to count using a block that returns a boolean" unless block_given?
    return 0 if self.empty?

    count = self.size
    match = 0
    self.each do |elem|
      match += 1 if yield(elem)
    end

    if digits
      ((match.to_f / count.to_f) * 100).round(digits)
    else
      ((match.to_f / count.to_f) * 100).to_i
    end
  end
end

Paint::SHORTCUTS[:color] = {
  :red    => Paint.color(:red),
  :orange => Paint.color('orange', :bright),
  :yellow => Paint.color(:yellow),
  :green  => Paint.color(:green),
}
include Paint::Color::Prefix::ColorName
