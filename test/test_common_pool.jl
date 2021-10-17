using MultiAgentEmergence

mypool = CommonPool()
mystate = CommonPoolState(0,0)
myresource = ResourceState(0,0)

@test typeof(mypool) == MultiAgentEmergence.CommonPool  

@test neighbors(mystate) == [ 
                            CommonPoolState(1, 0)
                            CommonPoolState(-1, 0)
                            CommonPoolState(0, -1)
                            CommonPoolState(0, 1)
                            ]
@test neighbors(myresource) == [
                                ResourceState(-1, -1)
                                ResourceState(-1, 0)
                                ResourceState(-1, 1)
                                ResourceState(0, -1)
                                ResourceState(0, 1)
                                ResourceState(1, -1)
                                ResourceState(1, 0)
                                ResourceState(1, 1)
                                ]

@test posequal(CommonPoolState(1,1),CommonPoolState(1,1))
@test posequal(ResourceState(1,1),ResourceState(1,1))


