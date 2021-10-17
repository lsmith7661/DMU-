# a simple 2D environment with common pool resources
using POMDPs, POMDPModelTools, POMDPPolicies, POMDPSimulators, StaticArrays

# agent
struct AgentState 
    x::Int64 # x position
    y::Int64 # y position
end

# resources
struct ResourceState
    x::Int64   # x position
    y::Int64   # y position
    on::Bool   # is resource available
    p::Float64 # probability of respawning
end
ResourceState(x::Int64, y::Int64) = ResourceState(x,y,true,0.01)
ResourceState(x::Int64, y::Int64, b::Bool) = ResourceState(x,y,b,0.01)
available(rsvec::AbstractArray{ResourceState}) = rsvec[getfield.(rsvec,:on)]
available(rs::ResourceState) = available([rs])

# mdp state
struct CommonPoolState
    Agent::AgentState
    #FIXME: Change to SVector
    Resource::AbstractArray{ResourceState}
end

# checks if the position of two states are the same
posequal(s1::Union{AgentState,ResourceState}, s2::Union{AgentState,ResourceState}) = s1.x == s2.x && s1.y == s2.y

# neighbors - returns grid neighbors of a commonpoolstate or a radius around a resourcestate
neighbors(s1::AgentState) = [
                            AgentState(s1.x+1, s1.y), # right
                            AgentState(s1.x-1, s1.y), # left
                            AgentState(s1.x, s1.y-1), # down
                            AgentState(s1.x, s1.y+1), # up
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

# respawn - probability that resource will respond as function of surrounding resources
function respawn(rs::ResourceState,rsvec::AbstractArray{ResourceState})
    num = length(findall(x->x in neighbors(rs), available(rsvec)))
    if num == 0
        p = 0.
    elseif num <= 2
        p = 0.01
    elseif num <= 4
        p = 0.05
    elseif num > 4
        p = 0.1
    end
    return ResourceState(rs.x,rs.y,rs.on,p)
end
function respawn!(rs::ResourceState,rsvec::AbstractArray{ResourceState}) 
    #FIXME: the bang versions of respawn don't mutate rs for whatever reason 
    rs = respawn(rs,rsvec)
end
respawn(rs::ResourceState,state::CommonPoolState) = respawn(rs,state.Resource)
function respawn(state::CommonPoolState) # update all resrouces in mdp
    newvec = ResourceState[] #FIXME: SVector
    rsvec = state.Resource
    for rs in rsvec
        push!(newvec,respawn(rs,rsvec))
    end
    return CommonPoolState(state.Agent,newvec)
end
function respawn!(state::CommonPoolState)
    #FIXME: the bang versions of respawn don't mutate rs for whatever reason 
    state = respawn(state)
end

# actions
action = :up # can also be :down, :left, :right

# the common pool world mdp type
struct CommonPool <: MDP{CommonPoolState, Symbol} # MDP is parametarized by the state and the action
    size_x::Int64                   # x size of the grid
    size_y::Int64                   # y size of the grid
    actionmap::Dict{Symbol,Int64}   # Dict(:right=>1, :left=>2, :down=>3, :up=>4)
    reward_val::Int64               # reward value for all resources
    discount_factor::Float64        # disocunt factor
end
function CommonPool(;
    sx::Int64=10,
    sy::Int64=10,
    amap::Dict=Dict(:right=>1, :left=>2, :down=>3, :up=>4),
    r::Int64=10,
    discount_factor::Float64=0.9
    )
    return CommonPool(sx, sy, amap, r, discount_factor)
end

# extend POMMDP.states()
function POMDPs.states(mdp::CommonPool)
    agent = AgentState[]        # initialize an array of agent states
    for y = 1:mdp.size_y, x = 1:mdp.size_x
        push!(agent, AgentState(x,y))
    end
    resource = ResourceState[]  # initialize an array of resource states
    for y = 1:mdp.size_y, x = 1:mdp.size_x, b = [true,false], p = [0.0,0.05,0.01,0.1]
        push!(resource, ResourceState(x,y,b,p))
    end
    s = CommonPoolState[]       # initialize an array of mdp states
    for a in agent, r in resource
        push!(s,CommonPoolState(a,r))
    end
end

# extend POMDP.actions()
POMDPs.actions(mdp::CommonPool) = [:up, :down, :left, :right];

 # bounds check
function inbounds(mdp::CommonPool,x::Int64,y::Int64)
    1 <= x <= mdp.size_x && 1 <= y <= mdp.size_y
end
inbounds(mdp::CommonPool, s::Union{AgentState,ResourceState}) = inbounds(mdp, s.x, s.y);

#=
# Transition
function POMDPs.transition(mdp::CommonPool, state::CommonPoolState, action::Symbol)
    a = action
    x = state.x
    y = state.y

    neighbors = [
        CommonPoolState(x+1, y), # right
        CommonPoolState(x-1, y), # left
        CommonPoolState(x, y-1), # down
        CommonPoolState(x, y+1), # up
        ] # See Performance Note below
    
    targets = Dict(:right=>1, :left=>2, :down=>3, :up=>4) # See Performance Note below
    target = targets[a]
    
    probability = fill(0.0, 4)

    if !inbounds(mdp, neighbors[target])
        # If would transition out of bounds, stay in
        # same cell with probability 1
        return SparseCat([GridWorldState(x, y)], [1.0])
    else
        probability[target] = mdp.tprob

        oob_count = sum(!inbounds(mdp, n) for n in neighbors) # number of out of bounds neighbors

        new_probability = (1.0 - mdp.tprob)/(3-oob_count)

        for i = 1:4 # do not include neighbor 5
            if inbounds(mdp, neighbors[i]) && i != target
                probability[i] = new_probability
            end
        end
    end

    return SparseCat(neighbors, probability)
end
=#