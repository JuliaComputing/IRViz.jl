"""
    viz(code_info)

Visualize the codeflow graph of of the given code_info.

Examples:
```julia
viz(@code_typed foo())
viz(@code_lowered bar())
````
"""
function viz end

viz((ci,_)::Pair{Core.CodeInfo}) = viz(ci)

function viz(ci::Core.CodeInfo)
    cfg = Core.Compiler.compute_basic_blocks(ci.code)
    edges = String[]
    for (start, blk) in enumerate(cfg.blocks)
        for finish in blk.succs
            push!(edges, "id$start --> id$finish")
        end
    end

    blocks_code = map(enumerate(cfg.blocks)) do (blk_ii, blk)
        code_lines = map(blk.stmts) do stmt_ii
            # TODO better rendering show types etc
            stmt = ci.code[stmt_ii]
            "%$stmt_ii = $stmt"
        end
        string("id$blk_ii(", block_label(code_lines), ")")
    end

    mermaid_src = """
    graph TD
    $(join(blocks_code, "\n"))

    $(join(edges, "\n"))
    """
    return Kroki.Diagram(:mermaid, mermaid_src)
end

function block_label(statements)
    join(statements, "\n") |>
    x->replace(x, "\""=>"&quot;") |> # most characters allows in quoted label but not quotation marks
    x->"\"$x\""
end