require "ripper"
require "pp"

class RipperLocals < Ripper::SexpBuilder
  def self.find_locals(code)
    instance = self.new(code)
    instance.parse
    instance.current_method.locals
  end

  attr_reader :current_method

  def initialize(*)
    super
    @parameters = []
    @local_variables = []
    @current_local_variables = []
    @current_method = nil
  end

  private

  def on_def(name, args, body)
    name = name[1]
    locals = (@parameters.pop || []) | (@local_variables.pop || [])
    method_defn = MethodDefinition.new(name: name, locals: locals)
    @current_method = method_defn
    super
  end

  def on_params(req_pos, opt_pos, splat_pos, _mystery_arg, keywords, splat_kw, block_arg)
    args = []
    @parameters.push(args)
    if req_pos
      args.concat(req_pos.map { |r| r[1] })
    end
    if opt_pos
      args.concat(opt_pos.map { |a| a[0][1] })
    end
    if splat_pos && splat_pos[1]
      args << splat_pos[1][1]
    end
    if keywords
      args.concat(keywords.map { |ident, def_val| ident[1].sub(":", "") })
    end
    if splat_kw && splat_kw[1]
      args << splat_kw[1][1]
    end
    if block_arg
      args << block_arg[1][1]
    end
    # p [req_pos, opt_pos, splat_pos, _mystery_arg, keywords, splat_kw, block_arg]
    super
  end

  def on_assign(lhs, rhs)
    if lhs[0] == :var_field
      recv = lhs[1]
      if recv[0] == :@ident
        @current_local_variables << recv[1]
      end
    end

    super
  end

  def on_massign(mlhs, mrhs)
    while mlhs[0] == :mlhs_add || mlhs[0] == :mlhs_add_star
      _token, next_mlhs, recv = mlhs
      if recv == [:mlhs_new]
        recv = mlhs[2]
      end
      if recv[0] == :var_field
        recv = recv[1]
        if recv[0] == :@ident
          @current_local_variables << recv[1]
        end
      end
      mlhs = next_mlhs
    end
    super
  end

  def on_stmts_add(lhs, rhs)
    if lhs == [:stmts_new]
      # p "New scope of #{@current_local_variables}"
      @local_variables.push(@current_local_variables)
    else
      # p "Add #{@current_local_variables} to scope of #{@local_variables.last}"
      @local_variables.last.concat(@current_local_variables)
    end
    @current_local_variables = []
    super
  end

  def on_do_block(*)
    # Remove the parameters and the locals,
    # we're not using them and only external locals count.
    @parameters.pop
    @local_variables.pop
    super
  end

  class MethodDefinition
    attr_reader :name, :locals
    def initialize(name:, locals:)
      @name = name
      @locals = locals
    end
  end
end
