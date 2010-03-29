require 'delegate'
module Reversal
  class IRList < DelegateClass(Array)
    def initialize(list)
      super(list)
      @source = list
    end

    def indent(amt = 2)
      @source.map! do |item|
        " " * amt + item.to_s
      end
    end

    def to_s
      @source.map {|x| x.to_s}.join("\n")
    end
  end
end