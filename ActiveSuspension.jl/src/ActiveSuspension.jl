module ActiveSuspension
using ActiveSuspensionModel: prob, sys, SystemParams
using OrdinaryDiffEq

function run(params::SystemParams)
    prob′ = remake(prob; p=sys .=> params)
    sol = solve(prob′; dtmax=0.1)

    return [sol.t sol[sys.road.s.u] sol[sys.wheel.m.s] sol[sys.car_and_suspension.m.s] sol[sys.seat.m.s]]
end

end # module ActiveSuspension
