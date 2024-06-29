using ActiveSuspensionModel: SystemParams, prob, sys
using DifferentialEquations

function run(params::SystemParams)
    prob′ = remake(prob; p=sys .=> params)
    sol = solve(prob′; dtmax=0.1)

    return [sol.t sol[sys.road.s.u] sol[sys.wheel.m.s] sol[sys.car_and_suspension.m.s] sol[sys.seat.m.s]]
end

params = SystemParams();
@time "run1" run(params);
@time "run2" run(params);
