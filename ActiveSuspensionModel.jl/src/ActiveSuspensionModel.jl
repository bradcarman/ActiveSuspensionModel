module ActiveSuspensionModel
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using ModelingToolkitStandardLibrary.Mechanical.Translational: Position, Damper, Force, PositionSensor
using ModelingToolkitStandardLibrary.Blocks
using DifferentialEquations
using RuntimeGeneratedFunctions
using PrecompileTools
RuntimeGeneratedFunctions.init(@__MODULE__)

# Model Parts -------------------------------------------

@connector MechanicalPort begin
    v(t)
    f(t), [connect = Flow]
end

@component function PassThru2(; name)
    @variables t

    systems = @named begin
        p1 = RealInput()
        p2 = RealOutput()
    end

    eqs = [connect(p1, p2)]

    return ODESystem(eqs, t, [], []; name, systems)
end

@component function PassThru3(; name)
    @variables t

    systems = @named begin
        p1 = MechanicalPort()
        p2 = MechanicalPort()
        p3 = MechanicalPort()
    end

    eqs = [connect(p1, p2, p3)]

    return ODESystem(eqs, t, [], []; name, systems)
end



@component function Mass(; name, m, g=0, s=0)
    pars = @parameters begin
        m=m
        g=g
    end
    vars = @variables begin
        s(t)=s
        v(t)=0
        f(t), [guess=0]
        a(t)=0
    end

    systems = @named begin
        flange = MechanicalPort()
    end 
    
    eqs = [
        v ~ flange.v
        f ~ flange.f

        D(s) ~ v
        D(v) ~ a
        m*a ~ f + m*g
    ]
    return ODESystem(eqs, t, vars, pars; name, systems)
end

@component function Spring(; name, k)
    pars = @parameters begin
        k = k
    end
    vars = @variables begin
        delta_s(t), [guess=0]
        f(t), [guess=0]
    end

    systems = @named begin
        flange_a = MechanicalPort()
        flange_b = MechanicalPort()
    end 
    
    eqs = [
        D(delta_s) ~ flange_a.v - flange_b.v
        f ~ k * delta_s
        flange_a.f ~ +f
        flange_b.f ~ -f
    ]
    return ODESystem(eqs, t, vars, pars; name, systems)
end


# ----------------------------------


@kwdef mutable struct RoadParams
    bump::Float64 = 0.2
    freq::Float64 = 0.5
    offset::Float64 = 1.0
    loop::Float64 = 10.0
end

function Base.show(io::IO, ::MIME"text/plain", x::RoadParams)
	println(io, "[RoadParams] \n bump=$(x.bump) \n freq=$(x.freq) \n offset=$(x.offset) \n loop=$(x.loop)")
end

Base.broadcasted(::Type{Pair}, model::ODESystem, pars::RoadParams) = [
    model.bump => pars.bump,
    model.freq => pars.freq,
    model.offset => pars.offset,
    model.loop => pars.loop
]


#y data as a function of time (assuming car is traveling at constant speed of 15m/s)
@component function Road(; name)
    
    systems = @named begin
        output = RealOutput()
    end
    
    pars = @parameters begin
        bump = 0.2
        freq = 0.5
        offset = 1.0
        loop = 10
    end

    𝕓 = bump*(1 - cos(2π*(t-offset)/freq))
    τ = mod(t, loop)

    eqs = [
        output.u ~ ifelse( τ < offset, 
            0.0, 
                ifelse( τ - offset > freq, 
                    0.0, 
                        𝕓)
        )
    ]

    return ODESystem(eqs, t, [], pars; name, systems)
end

@kwdef mutable struct ControllerParams
    kp::Float64 = 1.0
    ki::Float64 = 0.2
    kd::Float64 = 20.0
end

Base.broadcasted(::Type{Pair}, model::ODESystem, pars::ControllerParams) = [
    model.kp => pars.kp,
    model.ki => pars.ki,
    model.kd => pars.kd
]

function Base.show(io::IO, ::MIME"text/plain", x::ControllerParams)
	println(io, "[ControllerParams] \n kp=$(x.kp) \n ki=$(x.ki) \n kd=$(x.kd)")
end

@component function Controller(; name)
    
    pars = @parameters begin
        kp = 1
        ki = 1
        kd = 1
    end

    vars = @variables begin
        x(t) = 0
        dx(t) = 0
        ddx(t) = 0
        y(t) = 0
        dy(t) = 0
    end
    
    systems = @named begin
        err_input = RealInput()
        ctr_output = RealOutput()
    end


    # equations ---------------------------
    eqs = [

        D(x) ~ dx
        D(dx) ~ ddx
        D(y) ~ dy
        

        err_input.u ~ x
        ctr_output.u ~ y 

        dy ~ kp*(dx + ki*x + kd*ddx)

    ]

    return ODESystem(eqs, t, vars, pars; systems, name)
end

@kwdef mutable struct MassSpringDamperParams
    mass::Float64=1000.0
    stiffness::Float64=1e6
    damping::Float64=1e3
    initial_position::Float64=0.0
end

Base.broadcasted(::Type{Pair}, model::ODESystem, pars::MassSpringDamperParams) = [
    model.mass=>pars.mass
    model.stiffness=>pars.stiffness
    model.damping=>pars.damping
    model.initial_position=>pars.initial_position
]

function Base.show(io::IO, ::MIME"text/plain", x::MassSpringDamperParams)
	println(io, "[MassSpringDamperParams] \n mass=$(x.mass) \n stiffness=$(x.stiffness) \n damping=$(x.damping) \n initial_position=$(x.initial_position)")
end

@component function MassSpringDamper(;name, gravity=0.0)

    pars = @parameters begin
        mass=1000.0
        gravity=gravity
        stiffness=1e6
        damping=1e3
        initial_position=0.0
    end

    vars = []

    systems = @named begin
        d = Damper(; d=damping)
        m = Mass(;m=mass, g=gravity, s=initial_position)
        s = Spring(;k=stiffness)
        port_m = MechanicalPort()
        port_sd = MechanicalPort()

        pt3a = PassThru3()
        pt3b = PassThru3()
        
    end

    eqs = [       
        connect(pt3b.p1, d.flange_a)
        connect(pt3b.p2, s.flange_a)
        connect(pt3b.p2, m.flange)
        connect(pt3b.p3, port_m)

        
        connect(s.flange_b, pt3a.p1)
        connect(d.flange_b, pt3a.p2)
        connect(port_sd, pt3a.p3)
    ]

    return ODESystem(eqs, t, vars, pars; systems, name)
end

@kwdef mutable struct SystemParams
    gravity::Float64 = 0.0
    wheel::MassSpringDamperParams = MassSpringDamperParams(;mass=25, stiffness=1e2, damping=1e4)
    car_and_suspension::MassSpringDamperParams = MassSpringDamperParams(;mass=1000, stiffness=1e4, damping=10)
    seat::MassSpringDamperParams = MassSpringDamperParams(;mass=100, stiffness=1000, damping=1)
    road_data::RoadParams = RoadParams()
    pid::ControllerParams = ControllerParams()
end

Base.broadcasted(::Type{Pair}, model::ODESystem, pars::SystemParams) = [
    model.gravity => pars.gravity,
    (model.road_data .=> pars.road_data)...,
    (model.pid .=> pars.pid)...,
    (model.wheel .=> pars.wheel)...,
    (model.car_and_suspension .=> pars.car_and_suspension)...,
    (model.seat .=> pars.seat)...
]

function Base.show(io::IO, m::MIME"text/plain", x::SystemParams)
	println(io, "[SystemParams] \n gravity=$(x.gravity)") 
    print(io, "Wheel::")
    show(io, m, x.wheel)
    print(io, "Car::")
    show(io, m, x.car_and_suspension)
    print(io, "Seat::")
    show(io, m, x.seat)
    print(io, "Road::")
    show(io, m, x.road_data)
    print(io, "Controller::")
    show(io, m, x.pid)
end

@component function System(; name)

    
    pars = @parameters begin
          gravity = 0
    end

    vars = []

    sample_time = 1e-3 #TODO: why does this cause the model to fail if this is a parameter?

    systems = @named begin
        wheel = MassSpringDamper(; gravity) 
        car_and_suspension = MassSpringDamper(; gravity) 
        seat = MassSpringDamper(; gravity) 
        #road_data = SampledData(sample_time)
        road_data = Road()
        road = Position()
        force = Force()
        pid = Controller()
        err = Add(; k1=1, k2=-1) #makes a subtract
        set_point = Constant(; k=seat.initial_position) 
        seat_pos = PositionSensor(; s=seat.initial_position)
        flip = Gain(; k=-1)

        pt3 = PassThru3()
        pt2a = PassThru2()
        pt2b = PassThru2()
    end

    eqs = [
        
        # mechanical model
        connect(road.s, road_data.output)
        connect(road.flange, wheel.port_sd)
        connect(wheel.port_m, car_and_suspension.port_sd)
        connect(car_and_suspension.port_m, seat.port_sd)
        connect(seat.port_m, pt3.p1)
        connect(force.flange, pt3.p2)

        
        # controller        
        connect(pt3.p3, seat_pos.flange)
        connect(err.input1, pt2b.p1)
        connect(pt2b.p2, seat_pos.output)
        connect(err.input2, set_point.output)
        connect(pid.err_input, err.output)
        connect(pid.ctr_output, flip.input)
        connect(flip.output, pt2a.p1)
        connect(pt2a.p2, force.f)

        
    ]


    return ODESystem(eqs, t, vars, pars; systems, name)
end


@mtkbuild sys = System()
prob = ODEProblem(sys, [], (0, 10); eval_expression = false, eval_module = @__MODULE__)


# API -----------------

function show_params(params::SystemParams)
    display(params)
end

function copy_params(params::SystemParams)
    return copy(params)
end

function run(params::SystemParams)
    #BUG: see https://github.com/SciML/ModelingToolkit.jl/issues/2832
    prob′ = remake(prob; u0=Dict(), p=sys .=> params)
    sol = solve(prob′; dtmax=0.1)

    return [sol.t sol[sys.road.s.u] sol[sys.wheel.m.s] sol[sys.car_and_suspension.m.s] sol[sys.seat.m.s]]
end

@setup_workload begin   
    @compile_workload begin
        params = SystemParams()
        run(params)
    end
end

end # module ActiveSuspensionModel





