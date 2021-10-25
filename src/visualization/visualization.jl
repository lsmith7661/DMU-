## Visualize a CommonPool POMDP state - extends POMDPModelTools.render

function POMDPModelTools.render(mdp::CommonPool, step::Union{NamedTuple,Dict}=(;))

    # Grid World Sizes
    nx = mdp.size_x
    ny = mdp.size_y

    # An array of Compose.context() objects for drawing
    cells = [] 
    for x in 1:nx, y in 1:ny
        cell = cell_ctx(x,y,nx,ny)
        
        compose!(cell, rectangle(), fill("transparent"), stroke("gray"))
        push!(cells, cell)
    end

    # Grid
    grid = compose(context(), linewidth(0.5mm), cells...)
    outline = compose(context(), linewidth(1mm), rectangle(), fill("transparent"), stroke("gray"))

    if haskey(step, :s)
        s = step[:s]
        
        # Resources
        resource = Compose.Context[]
        for rs in s.Resources
            if rs.on
                resource_ctx = cell_ctx(rs.x,rs.y,nx,ny)
                resource = push!(resource,compose(resource_ctx, circle(0.5, 0.5, 0.4), fill("green")))
            end
        end

        # Agents - only one agent for now
        ag = s.Agent
        agent_ctx = cell_ctx(ag.x,ag.y,nx,ny)
        agent = compose(agent_ctx, circle(0.5, 0.5, 0.4), fill("red"))
    else
        resource = nothing
        agent = nothing
    end

    if haskey(step, :a)
        a = step[:a]
        action = compose(agent_ctx, text(0.5, 0.5, aarrow[a], hcenter, vcenter), stroke("black"),fontsize(24pt))
    else
        action = nothing
    end

    sz = min(w,h)
    aspx = max(nx,ny)
    aspx_x = sz*nx/aspx
    aspx_y = sz*ny/aspx
    return compose(context((w-aspx_x)/2, (h-aspx_y)/2, aspx_x, aspx_y), action, agent, grid, outline, resource...)
end

# Example render
render_example() = render(CommonPool(),(s=DefaultMap(CommonPool()),))

# Helper functions
cell_ctx(x,y,nx,ny) = context((x-1)/nx, (ny-y)/ny, 1/nx, 1/ny)
const aarrow = Dict(:up=>'↑', :left=>'←', :down=>'↓', :right=>'→')

# To print visualization to png
# NOTE: Must add Cairo, Fontconfig for draw to work. But they are large so not adding them for now....
# viz_png(context::Context) = draw(PNG("test.png",10inch,10inch),context)

# plot social metrics
function plot_socials(harray) # FIXME: an array of SimHistories does not work?? ::AbstractArray{POMDPSimulators.SimHistory})
    episodes = 1:length(harray)
    uarray = []
    earray = []
    susarray = []

    for h in harray
        push!(uarray,utility(h))
        push!(earray,equality(h))
        push!(susarray,sustainability(h))
    end

    p1 = plot(episodes, uarray, xlabel = "episode number", lw = 3, title = "Utility") 
    p2 = plot(episodes, earray, ylims=(0,1), xlabel = "episode number", lw = 3, title = "Equality") 
    p3 = plot(episodes, susarray, xlabel = "episode number", lw = 3, title = "Sustainability")
    plot(p1, p2, p3, layout = (1, 3), legend = false)

end

# plot social metrics
function plot_socials!(pref::Plot, harray) # FIXME: an array of SimHistories does not work?? ::AbstractArray{POMDPSimulators.SimHistory})
    episodes = 1:length(harray)
    uarray = []
    earray = []
    susarray = []

    for h in harray
        push!(uarray,utility(h))
        push!(earray,equality(h))
        push!(susarray,sustainability(h))
    end

    p1 = plot!(pref.subplots[1], episodes, uarray, xlabel = "episode number", lw = 3, title = "Utility") 
    p2 = plot!(pref.subplots[2], episodes, earray, ylims=(0,1), xlabel = "episode number", lw = 3, title = "Equality") 
    p3 = plot!(pref.subplots[3], episodes, susarray, xlabel = "episode number", lw = 3, title = "Sustainability")
    return pref
end