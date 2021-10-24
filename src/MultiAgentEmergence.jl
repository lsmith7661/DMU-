module MultiAgentEmergence

# Hello World
HelloWorld = "Hello World!"
export
    HelloWorld

# Example 
using POMDPs, QuickPOMDPs, POMDPModelTools, POMDPSimulators, QMDP
include("models/example_tiger_pomdp.jl")
export
    example_tiger_pomdp

# Common Pool
using POMDPs, POMDPModelTools, POMDPSimulators, StaticArrays, Random
include("models/common_pool.jl")
export
    CommonPool,
    CommonPoolState,
    AgentState,
    ResourceState,
    available,
    posequal,
    neighbors,
    respawn,
    inbounds,
    DefaultMap,
    RandomMap,
    utility,
    equality,
    sustainability

# Visualization
import POMDPModelTools: render
using Compose
import Plots: plot # Why do I need Unicode? Warning: Error requiring `UnicodePlots` from `Plots`

include("visualization/visualization.jl")
export 
    render,
    render_example,
    plot_socials

# Policies 
using POMDPPolicies, Random
include("policies/randompolicy.jl")
include("policies/greedypolicy.jl")
export
    random_policy,
    greedy_policy

end # module
