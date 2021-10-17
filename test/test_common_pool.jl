using MultiAgentEmergence

mypool = CommonPool()
mystate = CommonPoolState(5,5)
myresource = ResourceState(5,5)

@test typeof(mypool) == MultiAgentEmergence.CommonPool  

@test posequal(mystate,mystate)
@test posequal(myresource,myresource)

@test neighbors(mystate) == [ 
                            CommonPoolState(6, 5)
                            CommonPoolState(4, 5)
                            CommonPoolState(5, 4)
                            CommonPoolState(5, 6)
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

@test inbounds(mypool,mystate)
@test !inbounds(mypool,CommonPoolState(0,0))
@test inbounds(mypool,myresource)
@test !inbounds(mypool,ResourceState(0,0))

