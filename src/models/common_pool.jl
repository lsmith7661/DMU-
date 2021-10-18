# a simple 2D environment with common pool resources

# rng - default rng is repeatable
rng = MersenneTwister(1234)

# agent
struct AgentState 
    x::Int64 # x position
    y::Int64 # y position
end
AgentState() = AgentState(1,1)

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
    #FIXME: Change to SVectors
    Resources::AbstractArray{ResourceState}
end
CommonPoolState() = CommonPoolState()

# checks if the position of two states are the same
posequal(s1::Union{AgentState,ResourceState}, s2::Union{AgentState,ResourceState}) = s1.x == s2.x && s1.y == s2.y

# neighbors - returns grid neighbors of a commonpoolstate or a radius around a resourcestate
neighbors(s1::AgentState) = [
                            AgentState(s1.x+1, s1.y), # right
                            AgentState(s1.x-1, s1.y), # left
                            AgentState(s1.x, s1.y-1), # down
                            AgentState(s1.x, s1.y+1), # up
                            ]
function neighbors(s1::AgentState,r::Int64)
    cx = s1.x
    cy = s1.y
    s = AgentState[]
    for x in cx-r:cx+r 
        y = sqrt(r*r - (x-cx)*(x-cx))
        for y in cy-r:cy+r
            as = AgentState(x,y)
            if !posequal(s1,as)
                push!(s,as)
            end
        end
    end
    return s
end   
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
function respawn(rs::ResourceState,rsvec::AbstractArray{ResourceState},rng::AbstractRNG)
    
    # update respawn rate
    # num = length(findall(x->x in neighbors(rs), available(rsvec))) # how annons work with two varrrrs :(
    temp1 = []
    for n in neighbors(rs)
        temp2 = []
        for ar in available(rsvec)
            push!(temp2,posequal(n,ar))
        end
        push!(temp1,any(temp2))
    end
    num = sum(temp1)

    if num == 0
        p = 0.
    elseif num <= 2
        p = 0.01
    elseif num <= 4
        p = 0.05
    elseif num > 4
        p = 0.1
    end

    # respawn?
    on = any([rs.on,p > rand(rng)])

    return ResourceState(rs.x,rs.y,on,p)
end
respawn(rs::ResourceState,rsvec::AbstractArray{ResourceState}) = respawn(rs,rsvec,rng)
respawn(rs::ResourceState,state::CommonPoolState) = respawn(rs,state.Resource)
function respawn(rsvec::AbstractArray,rng::AbstractRNG) # update all resrouces in an array
    #FIXME: SVector
    newvec = ResourceState[] 
    for rs in rsvec
        push!(newvec,respawn(rs,rsvec,rng))
    end
    return newvec
end
respawn(rsvec::AbstractArray) = respawn(rsvec,rng)

# actions
right(agent::AgentState) = AgentState(agent.x+1,agent.y)
left(agent::AgentState) = AgentState(agent.x-1,agent.y)
up(agent::AgentState) = AgentState(agent.x,agent.y+1)
down(agent::AgentState) = AgentState(agent.x,agent.y-1)

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

# need to use generative model
#= extend POMMDP.states() 
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
    #FIXME: CommonPoolStates contain array of resources, not resources.... gaaaah
    for a in agent, r in resource
        push!(s,CommonPoolState(a,r))
    end
end =#

# extend POMDP.actions()
POMDPs.actions(mdp::CommonPool) = [:up, :down, :left, :right];

 # bounds check
function inbounds(mdp::CommonPool,x::Int64,y::Int64)
    1 <= x <= mdp.size_x && 1 <= y <= mdp.size_y
end
inbounds(mdp::CommonPool, s::Union{AgentState,ResourceState}) = inbounds(mdp, s.x, s.y);

# generative model
function POMDPs.gen(m::CommonPool, s::CommonPoolState, a::Symbol, rng::AbstractRNG)
    
    # update agent deterministically, Dict(:right=>1, :left=>2, :down=>3, :up=>4)
    @assert(any(x->x==a, POMDPs.actions(m)))
    if a == :right
        agent = right(s.Agent)
    elseif a == :left
        agent = left(s.Agent)
    elseif a == :down
        agent = down(s.Agent)
    elseif a == :up
        agent = up(s.Agent)
    end

    # enforce bounds on new agent sate
    if !inbounds(m,agent)
        agent = s.Agent
    end

    # add reward if at resource, turn off reward if collected
    r = 0
    resources = ResourceState[]
    for rs in s.Resources
        if posequal(agent,rs) && rs.on
            r = m.reward_val
            push!(resources,ResourceState(rs.x,rs.y,false,rs.p))
        else
            push!(resources,rs)
        end
    end

    # update resources respawn probabilities
    resources = respawn(resources,rng)

    # update state (s')
    sp = CommonPoolState(agent,resources)
    
    # observation model - boolean array, true if neighbor is an active resource square
    #FIXME: what the heck should this be
    o = []
    for n in neighbors(agent,1)
        temp = []
        for rs in available(resources)
            push!(temp,posequal(n,rs))
        end
        push!(o,any(temp))
    end

    # create and return a NamedTuple for POMDPs interface
    return (sp=sp, o=o, r=r)
end
POMDPs.gen(m::CommonPool, s::CommonPoolState, a::Symbol) = POMDPs.gen(m, s, a, rng)

# default starting maps
function DefaultMap(mdp::CommonPool) 
    @assert(mdp.size_x > 3)
    @assert(mdp.size_y > 3)
    cx = trunc(Int64,mdp.size_x/2)
    cy = trunc(Int64,mdp.size_y/2)
    Resources = [
        ResourceState(cx,cy),
        ResourceState(cx+1,cy),                
        ResourceState(cx-1,cy),
        ResourceState(cx,cy+1),                
        ResourceState(cx,cy-1)
        ]
    return CommonPoolState(AgentState(1,1),Resources)
end

function RandomMap(mdp::CommonPool,rng::AbstractRNG) 
    @assert(mdp.size_x > 3)
    @assert(mdp.size_y > 3)
    cx = rand(rng,1:mdp.size_x)
    cy = rand(rng,1:mdp.size_y)
    Resources = [
        ResourceState(cx,cy),
        ResourceState(cx+1,cy),                
        ResourceState(cx-1,cy),
        ResourceState(cx,cy+1),                
        ResourceState(cx,cy-1)
        ]
    ResourcesPruned = ResourceState[]
    for r in Resources
        if inbounds(mdp,r)
            push!(ResourcesPruned,r)
        end
    end
    return CommonPoolState(AgentState(rand(rng,1:mdp.size_x),rand(rng,1:mdp.size_y)),ResourcesPruned)
end  
RandomMap(mdp::CommonPool) = RandomMap(mdp,rng)