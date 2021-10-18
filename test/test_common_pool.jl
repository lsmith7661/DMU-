using MultiAgentEmergence

mypool = CommonPool()
myagent = AgentState(5,5)
myresource = ResourceState(5,5)
resourcevec = [ResourceState(4,4),ResourceState(5,6),ResourceState(4,5,false)]

# type
@test typeof(mypool) == MultiAgentEmergence.CommonPool  

# available
@test length(available(ResourceState(5,5,false))) == 0
@test length(available(myresource)) == 1
@test length(available([myresource, myresource])) == 2
@test length(available([myresource, myresource,ResourceState(5,5,false)])) == 2
@test length(available([myresource, myresource,ResourceState(5,5,true)])) == 3

# posequal
@test posequal(myagent,myagent)
@test posequal(myresource,myresource)

# neighbors
@test neighbors(myagent) == [ 
                            AgentState(6, 5)
                            AgentState(4, 5)
                            AgentState(5, 4)
                            AgentState(5, 6)
                            ]
@test neighbors(myresource) == [
                                ResourceState(4, 4)
                                ResourceState(4, 5)
                                ResourceState(4, 6)
                                ResourceState(5, 4)
                                ResourceState(5, 6)
                                ResourceState(6, 4)
                                ResourceState(6, 5)
                                ResourceState(6, 6)
                                ]

# respawn
#TODO

# inbounds
@test inbounds(mypool,myagent)
@test !inbounds(mypool,AgentState(0,0))
@test inbounds(mypool,myresource)
@test !inbounds(mypool,ResourceState(0,0))

