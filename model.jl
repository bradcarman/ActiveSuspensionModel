using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using ModelingToolkitStandardLibrary.Mechanical.Translational
using ModelingToolkitStandardLibrary.Blocks
using ModelingToolkitDesigner
using CairoMakie
using GLMakie
using DataInterpolations
using DifferentialEquations


dx = 0.01
xspan = 100
x = 0:dx:xspan

y = [
    zeros(round(Int,xspan/dx));
    0.1*sin.(2*π*1*x);
    0.1*sin.(2*π*1*x);
    0.1*sin.(2*π*1*x);
    0.1*sin.(2*π*1*x);
]


using CatapultFunctions

X = collect(0:dx:dx*(length(y)-1))
Y = butterworth(y, dx; cutoff=1, pole=2)
YF = LinearInterpolation(Y, X)


function ActiveDamper(; name, damping)

    pars = []

    vars = @variables begin
        damping(t)=damping
    end

    systems = @named begin
        input = RealInput(; guess=damping)
        flange_a = MechanicalPort()
        flange_b = MechanicalPort()
    end

    # let
    v = flange_a.v - flange_b.v
    f = damping*v

    eqs = [
        damping ~ input.u
        flange_a.f ~ +f
        flange_b.f ~ -f
    ]

    return ODESystem(eqs, t, vars, pars; systems, name)
end


function MassSpringDamper(is_active::Bool; name, mass, gravity, damping, stiffness, initial_position)

    pars = @parameters begin
        mass=mass
        gravity=gravity
        stiffness=stiffness
    end

    vars = []

    systems = @named begin
        d = ActiveDamper(; damping)
        m = Mass(;m=mass, g=gravity, s=initial_position)
        s = Spring(;k=stiffness)
        port_m = MechanicalPort()
        port_sd = MechanicalPort()
    end

    eqs = [
        connect(m.flange, s.flange_a, d.flange_a, port_m)
        connect(s.flange_b, d.flange_b, port_sd)
    ]

    if is_active
        @named damping_input = RealInput(; guess=damping)
        push!(systems, damping_input)
        push!(eqs, connect(damping_input, d.input))
    else
        @parameters damping=damping
        push!(pars, damping)
        push!(eqs, d.input.u ~ damping)
    end

    return ODESystem(eqs, t, vars, pars; systems, name)
end

function System(; name)

    pars = @parameters begin
        gravity = 0
        
        wheel_mass = 25 #kg
        wheel_stiffness = 1e2
        wheel_damping = 1e4

        car_mass = 1000 #kg
        suspension_stiffness = 1e4
        suspension_damping = 10

        human_and_seat_mass = 100
        seat_stiffness = 1
        seat_damping = 0

        car_velocity = 1

        Kp=1
        Kd=1
        Ki=1
    end

    vars = @variables begin
        x(t)=0
        err(t)=0
        derr(t)=0
        dderr(t)=0
        active_damping(t)=seat_damping
        dactive_damping(t)=0
    end


    systems = @named begin
        wheel = MassSpringDamper(false; mass=4*wheel_mass, gravity, damping=wheel_damping, stiffness=wheel_stiffness, initial_position=0.5)
        car_and_suspension = MassSpringDamper(false; mass=car_mass, gravity, damping=suspension_damping, stiffness=suspension_stiffness, initial_position=1)
        seat = MassSpringDamper(true; mass=4*human_and_seat_mass, gravity, damping=seat_damping, stiffness=seat_stiffness, initial_position=1.5)
        road = Position()

    end

    eqs = [
        D(x) ~ car_velocity
        road.s.u ~ YF(x)

        connect(road.flange, wheel.port_sd)
        connect(wheel.port_m, car_and_suspension.port_sd)
        connect(car_and_suspension.port_m, seat.port_sd)

        # controller
        err ~ seat.m.s - 1.5
        D(err) ~ derr
        D(derr) ~ dderr
        D(active_damping) ~ dactive_damping
        dactive_damping ~ Kp*derr + Kp*Ki*err + Kp*Kd*dderr

        seat.damping_input.u ~ active_damping
    ]


    return ODESystem(eqs, t, vars, pars; systems, name)
end


@mtkbuild sys = System()
prob = ODEProblem(sys, [], (0, maximum(X)))

begin   
    prob = remake(prob; u0=[sys.active_damping=>0], p=[sys.Kp=>1, sys.Ki=>200, sys.Kd=>1, sys.seat_stiffness=>10])
    sol = solve(prob)

    CairoMakie.activate!()

    fig = Figure()
    ax = Axis(fig[1,1])
    lines!(ax, sol.t, sol[sys.seat.m.s])
    # lines!(ax, sol.t, sol[sys.car_and_suspension.m.s])
    # lines!(ax, sol.t, sol[sys.wheel.m.s])
    # lines!(ax, sol.t, sol[sys.road.s.u])
    ylims!(ax, 1.45, 1.55)

    ax = Axis(fig[2,1])
    lines!(ax, sol.t, sol[sys.active_damping])
    fig    
end


vars = @variables x(t)=0
@mtkbuild sys = ODESystem(D(x) ~ 1, t, vars, [])
prob = ODEProblem(sys, [], (0, 1))
sol = solve(prob; dtmax=0.1)


