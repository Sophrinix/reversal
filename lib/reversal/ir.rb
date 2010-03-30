module Reversal
  class Sexp < Array
    def initialize(*args)
      super
      if self.respond_to?("post_init_#{self.type}".to_sym)
        send("post_init_#{self.type}".to_sym)
      end
    end

    def type
      self.first
    end
    def body
      self[1..-1]
    end

    def simple?
      ![:infix, :if, :else, :setvar, :aset].include?(self.type)
    end

    def nil?
      self.type == :nil
    end

    def true?
      self.type == :lit && self[1] == true
    end

    def fixnum?
      self.type == :lit && self[1].is_a?(Fixnum)
    end

    def to_s
      if self.respond_to?("to_s_#{self.type}".to_sym)
        send("to_s_#{self.type}".to_sym)
      else
        super
      end
    end

    ####### to_s methods #########
    def to_s_lit
      # [:lit, 5]
      self[1].inspect
    end

    def to_s_getvar
      # [:getvar, :HELLO]
      # [:getvar, :@hello]
      self[1].to_s
    end

    def to_s_setvar
      "#{self[1]} = #{self[2]}"
    end

    def to_s_splat
      "*#{self[1]}"
    end

    def to_s_array
      "[#{self[1].map {|x| x.to_s}.join(", ")}]"
    end

    def to_s_range
      start, stop, flag = self[1..-1]
      if flag # inclusive?
        "(#{start}..#{stop})"
      else
        "(#{start}...#{stop})"
      end
    end

    def to_s_infix
      operator, args  = self[1], self[2]
      need_parens = (args.all? {|x| x.is_a?(Sexp) && x.simple?})
      if need_parens
        args.map {|a| a.to_s}.join(" #{operator} ")
      else
        args = args.map do |arg|
          arg.simple? ? arg.to_s : "(#{arg.to_s})"
        end
        "(" + args.join(" #{operator} ") + ")"
      end
    end

    def to_s_hash
      list = self[1]
      list.map! {|(k, v)| "#{k} => #{v}" }
      "{#{list.join(', ')}}"
    end

    def to_s_nil
      "nil"
    end

    def to_s_not
      "!#{self[1]}"
    end

    def to_s_aref
      "#{self[1]}[#{self[2]}]"
    end

    def to_s_aset
      "#{self[1]}[#{self[2]}] = #{self[3]}"
    end

    def to_s_block
      whole_iseq, body = self.body
      args = whole_iseq.argstring
      args = "|#{args}|" if whole_iseq.stats[:arg_size] > 0
      result = []
      result << " do #{args}"
      result << body.indent.to_s
      result << "end"
      result.join("\n")
    end

    def post_init_defmethod
      receiver, name, blockiseq, parent = self.body
      name = name.to_s
      # alter name if necessary
      name = name[1..-1] if name[0,1] == ":" # cut off leading :
      name = (receiver.kind_of?(Integer) || receiver.fixnum?) ? "#{name}" : "#{receiver}.#{name}"
      self[2] = name
      reverser = Reverser.new(blockiseq, parent)
      self[5] = IRList.new(reverser.decompile_body)
    end

    def to_s_defmethod
      receiver, name, iseq, parent, code = self.body
      iseq = ISeq.new(iseq)
      args = iseq.argstring
      args = "(#{args})" if iseq.stats[:arg_size] > 0
      result = []
      result << "def #{name}#{args}"
      result << code.indent.to_s
      result << "end"
      result.join("\n")
    end

    def post_init_send
      blockiseq, parent = self[4], self[5]
      if blockiseq
        reverser = Reverser.new(blockiseq, parent)
        self[4] = IRList.new([reverser.to_ir])
      end
    end

    def to_s_send
      meth, receiver, args, blockiseq, parent = self.body
      result = meth.to_s
      result = "#{receiver}.#{result}" unless receiver == :implicit
      result << (args.any? ? "(#{args.map {|a| a.to_s}.join(", ")})" : "")

      if blockiseq
        result << blockiseq.to_s
      end
      result
    end

    def to_s_general_module
      type, name, ir, data = self.body
      case type
      when :module
        first_line = "module #{data[0]}#{name}"
      when :metaclass
        first_line = "class << #{data[0]}"
      when :class
        first_line = "class #{data[0]}#{name}#{data[1]}"
      end
      definition = ir.map {|x| x.to_s.split("\n").map {|x| "  " + x}.join("\n")}.join("\n")     
      result = []
      result << first_line
      result << definition.to_s
      result << "end"
      result.join("\n")
    end
  end
end

module Kernel
  def r(*args)
    Reversal::Sexp.new(args)
  end
end