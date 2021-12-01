# Move in the direction of most resources in observation space


function greedy(input::Union{Deterministic,AbstractArray{Any}})

    # Dont understand why the input is a state distribution 
    # sometimes and not an observation distribution

    """
    Observation Distribution, o_dist, is an distribution of
    boolean arrays generated from neighbors(agent,obs_range) 
    && if resource.on. Usually deterministic but maybe not
    one day...
    """

    # Input Handling
    if input isa Deterministic
        sp_dist = input

        # Create observations from state
        o_dist = POMDPs.observation(rand(sp_dist))

        # Sample from observation distribution
        o = rand(o_dist)
    else
        o = input
    end

    # Reshape array into a grid around agent
    sz = Int(sqrt(length(o)))
    obsgrid = reshape(o, sz, sz)
    obsgrid = obsgrid[end:-1:1,:] # need to flip vertically cause unwrapping

    # center of grid
    c = Int(round(sz/2))

    # sum in each direction of the center
    leftsum = sum(obsgrid[:,1:c-1])
    rightsum = sum(obsgrid[:,c+1:end])
    upsum = sum(obsgrid[1:c-1,:])
    downsum = sum(obsgrid[c+1:end,:])

    # return action in the direction of largest sum
    # FIXME: This biases left -> down -> right -> up, if equal
    dir = max(leftsum,rightsum,upsum,downsum)
    if dir == 0
        return rand([:up, :down, :left, :right])
    elseif dir == leftsum
        return :left
    elseif dir == downsum
        return :down
    elseif dir == rightsum
        return :right
    elseif dir == upsum
        return :up
    end 
end
    

"""
FunctionPolicy
Policy p = FunctionPolicy(f) returns f(x) when action(p, x) is called.

action(policy::Policy, x)
Returns the action that the policy deems best for the current state or 
belief, x. x is a generalized information state - can be a state in an 
MDP, a distribution in POMDP, or another specialized policy-dependent 
representation of the information needed to choose an action.
"""
greedy_policy = FunctionPolicy( o -> greedy(o) )
