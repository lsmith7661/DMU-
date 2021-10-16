using MultiAgentEmergence

@test MultiAgentEmergence.HelloWorld == "Hello World!"
@test MultiAgentEmergence.example_tiger_pomdp() <= 23.0