using Test
using CompilerPluginTools

const GLOBAL_CONST = 2.0

struct Foo
    x::Int
end

@testset "inline_const" begin
    ir = @ircode begin
        Expr(:call, Core.Intrinsics.abs_float, 1.0)::Float64
        GlobalRef(Main, :GLOBAL_CONST)::Float64
        ReturnNode(SSAValue(1))::Float64
    end
    
    ir = inline_const!(ir)
    @test ir.stmts[1][:inst] == 1.0
    @test ir.stmts[1][:type] == Const(1.0)
    @test ir.stmts[2][:inst] == 2.0
    @test ir.stmts[2][:type] == Const(2.0)

    ir = @ircode begin
        Expr(:call, Core.Intrinsics.abs_float, 1.0)::Float64
        Expr(:new, Foo, 2)::Foo
        ReturnNode(SSAValue(1))::Float64
    end
    
    ir = inline_const!(ir)

    @test ir.stmts[2][:inst] == QuoteNode(Foo(2))
    @test ir.stmts[2][:type] == Const(Foo(2))

    ir = @ircode begin
        QuoteNode(1)::Int
        Expr(:new, Foo, SSAValue(1))::Foo
        ReturnNode(SSAValue(1))::Int
    end
    ir = inline_const!(ir)
    @test ir.stmts[2][:inst] == QuoteNode(Foo(1))
    @test ir.stmts[2][:type] == Const(Foo(1))

    ir = @ircode begin
        Expr(:call, Core.tuple, 1, 2, 3)::Tuple{Int, Int, Int}
        ReturnNode(SSAValue(1))::Tuple{Int, Int, Int}
    end
    ir = inline_const!(ir)
    @test ir.stmts[1][:inst] == (1, 2, 3)
    @test ir.stmts[1][:type] == Const((1, 2, 3))
end

@testset "permute_stmts!" begin
    ir = @ircode begin
        QuoteNode(1.0)::Const(1.0)
        Expr(:call, sin, SSAValue(1))::Float64
        QuoteNode(2.0)::Const(2.0)
        Expr(:call, sin, SSAValue(3))::Float64
        ReturnNode(SSAValue(2))::Float64
    end
    
    ir = permute_stmts!(ir, [1, 3, 2, 4, 5])
    @test ir.stmts[1][:inst] == QuoteNode(1.0)
    @test ir.stmts[2][:inst] == QuoteNode(2.0)
    @test ir.stmts[3][:inst] == Expr(:call, sin, SSAValue(1))
    @test ir.stmts[4][:inst] == Expr(:call, sin, SSAValue(2))        
end
