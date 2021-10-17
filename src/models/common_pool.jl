# a simple 2D environment with common pool resources
using POMDPs, POMDPModelTools, POMDPPolicies, POMDPSimulators

# states
struct CommonPoolState 
    x::Int64 # x position
    y::Int64 # y position
    #done::Bool # are we in a terminal state?
end
# CommonPoolState(x::Int64, y::Int64) = CommonPoolState(x,y,false)

# resources
struct ResourceState
    x::Int64   # x position
    y::Int64   # y position
    r::Int64   # reward value
    on::Bool  # is resource available
    p::Float64 # probability of replentishing
end
ResourceState(x::Int64, y::Int64) = ResourceState(x,y,10,true,0.01)
ResourceState(x::Int64, y::Int64, r::Int64) = ResourceState(x,y,r,true,0.01)

# checks if the position of two states are the same
posequal(s1::Union{CommonPoolState,ResourceState}, s2::Union{CommonPoolState,ResourceState}) = s1.x == s2.x && s1.y == s2.y

# neighbors - returns grid neighbors of a commonpoolstate or a radius around a resourcestate
neighbors(s1::CommonPoolState) = [
                                CommonPoolState(s1.x+1, s1.y), # right
                                CommonPoolState(s1.x-1, s1.y), # left
                                CommonPoolState(s1.x, s1.y-1), # down
                                CommonPoolState(s1.x, s1.y+1), # up
                                ]
function neighbors(s1::ResourceState, r::Int64)
    cx = s1.x
    cy = s1.y
    s = ResourceState[]
    for x in cx-r:cx+r 
        y = sqrt(r*r - (x-cx)*(x-cx))
        for y in cy-r:cy+r
            rs = ResourceState(x,y)
            if !posequal(s1,rs)
                push!(s,rs)
            end
        end
    end
    return s
end
neighbors(s1::ResourceState) = neighbors(s1::ResourceState,1)

# actions
action = :up # can also be :down, :left, :right

# the common pool world mdp type
mutable struct CommonPool <: MDP{CommonPoolState, Symbol} # MDP is parametarized by the state and the action
    size_x::Int64 # x size of the grid
    size_y::Int64 # y size of the grid
    reward_states::Vector{ResourceState} # the states in which agents recieves reward
    tprob::Float64 # probability of transitioning to the desired state
    discount_factor::Float64 # disocunt factor
end
function CommonPool(;
    sx::Int64=10, # size_x
    sy::Int64=10, # size_y
    rs::Vector{ResourceState}=[ResourceState(4,3), ResourceState(4,5), ResourceState(3,4), ResourceState(5,4)], # reward states
    tp::Float64=1., # tprob
    discount_factor::Float64=0.9)
    return CommonPool(sx, sy, rs, tp, discount_factor)
end

# extend POMMDP.states()
function POMDPs.states(mdp::CommonPool)
    s = CommonPoolState[] # initialize an array of CommonPoolStates
    for y = 1:mdp.size_y, x = 1:mdp.size_x
        push!(s, CommonPoolState(x,y))
    end
    return s
end

# extend POMDP.actions()
POMDPs.actions(mdp::CommonPool) = [:up, :down, :left, :right];

 # bounds check
function inbounds(mdp::CommonPool,x::Int64,y::Int64)
    1 <= x <= mdp.size_x && 1 <= y <= mdp.size_y
end
inbounds(mdp::CommonPool, s::Union{CommonPoolState,ResourceState}) = inbounds(mdp, s.x, s.y);
