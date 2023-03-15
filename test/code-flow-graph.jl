macro example(name, code)
    quote
        @testset $name begin
            function runit()
                $code
            end
            @test_reference "refs/$($name).png" viz(@code_typed optimize=false runit())
        end
    end
end

@example "trival" begin
    42
end

@example "trival String" begin
    "Life"
end

@example "basics" begin
    x = "abc"
    x_len = length(x)
    return 2*x_len
end

@example "loop" begin
    x = 1
    y = 1
    while x < 100
        x*=2
        y+=1
    end
    return y
end

function foo()
    x = 1
    y = 0
    while x < 100
        x*=2
        y+=1
    end
    return y
end