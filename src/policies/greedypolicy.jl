# Move in the direction of most resources in observation space

function greedy(o::AbstractArray{Bool})

    """
    Observation, o, is an boolean array generated 
    from neighbors(agent,obs_range) && if resource.on
    """

    # Reshape array into a grid around agent
    sz = sqrt(length(o))
    obsgrid = reshape(o, sz, sz)

    # center of grid
    c = round(sz/2)

    # sum in each direction of the center
    leftsum = sum(obsgrid[:,1:c])
    rightsum = sum(obsgrid[:,c:end])
    upsum = sum(obsgrid[1:c,:])
    downsum = sum(obsgrid[c:end,:])

    # return action in the direction of largest sum
    # FIXME: This biases left -> right -> down -> up, if equal
    dir = max(leftsum,rightsum,upsum,downsum)
    if dir == leftsum
        return :left
    elseif dir == rightsum
        return :right
    elseif dir == downsum
        return :down
    elseif dir == upsum
        return :up
    end 
end
    
greedy_policy = FunctionPolicy( o -> greedy(o) )
