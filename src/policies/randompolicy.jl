# Creates a random action for any observation in CommonPool MDP
random_policy = FunctionPolicy( o -> rand([:up, :down, :left, :right]))
