using Test

@testset "EnvironmentTest" begin
    include("test_env.jl")
end

@testset "CommonPoolTest" begin
    include("test_common_pool.jl")
end
