# Move to and then along a predefined path

function deterministic_path(pomdp::CommonPool, s::CommonPoolState)

    a_array = Symbol[]

    # Agent Starting Location
    x = s.Agent.x
    y = s.Agent.y

    # Get to path corner (2,3)
    while x != 2
        dx = 2 - x
        if dx < 0 
            push!(a_array, :left)
            x += -1
        else
            push!(a_array,:right)
            x += 1
        end
    end
    while y != 3
        dy = 3 - x
        if dy < 0 
            push!(a_array, :down)
            y += -1
        else
            push!(a_array,:up)
            y += 1
        end
    end
        
    # Create path
    while length(a_array) < 1000
        if x == 2 && y < pomdp.size_y-2
            push!(a_array,:up)
            y += 1     
        elseif x < pomdp.size_x-1 && y == pomdp.size_y-2
            push!(a_array,:right)
            x += 1
        elseif x == pomdp.size_x-1 && y > 3
            push!(a_array,:down)
            y += -1
        elseif x > 2 && y == 3
            push!(a_array,:left)
            x += -1
        end
    end

    return a_array
end

# Create PlaybackPolicy
path_policy(pomdp::CommonPool, s::CommonPoolState) = 
    PlaybackPolicy(
        deterministic_path(pomdp, s), # actions
        random_policy,  # backup policy
        Float64[], # logpdf?
        1) # starting index
       
## Belief Stuff
POMDPs.updater(::PlaybackPolicy) = NothingUpdater()

    