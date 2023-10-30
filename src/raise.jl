using Core.Compiler: IRCode
using Core: SSAValue
using Base.Meta: isexpr
function raise(ir::IRCode)
    ir = copy(ir)
    ssa_used_in = ssa_use_graph(ir)
    out_stmts = Vector()
    for ii in length(ir.stmts):-1:1
        stmt_ssa = SSAValue(ii)
        new_stmt = raise!(ir, ssa_used_in, stmt_ssa)
        isnothing(new_stmt) && continue
        pushfirst!(out_stmts, stmt_ssa => new_stmt)
    end
    return out_stmts
end

function raise!(ir::IRCode, ssa_used_in, ssa::SSAValue)
    stmt = ir[ssa].stmt
    new_stmt = if isexpr(stmt, :call)
        raise_call_or_invoke!(ir, ssa_used_in, stmt.args...)
    elseif isexpr(stmt, :invoke) 
        raise_call_or_invoke!(ir, ssa_used_in, stmt.args[2:end]...)
    else
        stmt
    end
    ir[ssa].stmt = nothing
    return new_stmt
end

function raise_call_or_invoke!(ir::IRCode, ssa_used_in, f, args...)
    head = raise_function_ref(f)
    if head == :getfield
        return Expr(:., args[1], args[2])
    end
    args = map(args) do arg
        if (arg isa SSAValue)
            uses = ssa_used_in[arg]
            if length(uses) == 1  # Proactively raise it here, inline
                return raise!(ir, ssa_used_in, arg)
            end
        end
        return arg
    end
    Expr(:call, head, args...)
end
function raise_function_ref(head::GlobalRef)
    (;name, mod) = head   
    if mod == Base
        name = if name ∈ (:div_float, :div_int)
            :/
        elseif name ∈ (:mul_float, :mul_int)
            :*
        elseif name ∈ (:sub_float, :sub_int, :neg_float, :neg_int)
            :-
        elseif name ∈ (:add_float, :add_int)
            :+
        else 
            name
        end
    end
    return name  # just drop the module name
end
raise_function_ref(head::Function) = nameof(head)
raise_function_ref(head) = head

function ssa_use_graph(ir::IRCode)
    used_in = Dict{SSAValue, Vector{SSAValue}}()
    sizehint!(used_in, length(ir.stmts))
    for ii in 1:length(ir.stmts)
        stmt_ssa = SSAValue(ii)
        stmt = ir[stmt_ssa].stmt
        if stmt isa Expr
            for arg in stmt.args
                if arg isa SSAValue
                    @assert arg < stmt_ssa
                    uses = get!(Vector{SSAValue}, used_in, arg)
                    push!(uses, stmt_ssa)
                end
            end
        end
    end
    return used_in
end

raise(ir)