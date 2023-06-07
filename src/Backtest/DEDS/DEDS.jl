"""
    DEDS - Which stands for "Discrete Event Driven Simulation"  is a framework for backtesting
    where the system moves from one event to the next one.
"""
module DEDS

"""
    DEDS module hello world
"""
function hello_deds()
    return "Hello D.E.D.S.!"
end

"""
    Run DEDS simulation
"""
function run()
    event_queue = [] # Potentially this can be inside context, so that the client can interact with it. Assuming the client is modelled through a Module.
    return event_queue
end

end
