module ActiveSuspensionModel
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using DifferentialEquations
using RuntimeGeneratedFunctions
using PrecompileTools
RuntimeGeneratedFunctions.init(@__MODULE__)

# base model components
include("components.jl")

# top level model 
# -----------------------------------------------------
@kwdef mutable struct RoadParams
    bump::Float64 = 0.2
    freq::Float64 = 0.5
    offset::Float64 = 1.0
    loop::Float64 = 10.0
end

function Base.show(io::IO, ::MIME"text/plain", x::RoadParams)
	println(io, "[RoadParams] \n bump=$(x.bump) \n freq=$(x.freq) \n offset=$(x.offset) \n loop=$(x.loop)")
end

Base.copy(x::RoadParams) = RoadParams(x.bump, x.freq, x.offset, x.loop)

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

Base.copy(x::ControllerParams) = ControllerParams(x.kp, x.ki, x.kd)

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
        initial_output = 0
    end

    vars = @variables begin
        x(t), [guess=0]
        dx(t), [guess=0]
        ddx(t), [guess=0]
        y(t)=initial_output
        dy(t), [guess=0]
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

function Base.setproperty!(value::MassSpringDamperParams, name::Symbol, x)
    if name == :mass
        @assert x > 0 "mass must be greater than 0"
    end
    Base.setfield!(value, name, x)
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

Base.copy(x::MassSpringDamperParams) = MassSpringDamperParams(x.mass, x.stiffness, x.damping, x.initial_position)

# INIT NOTE: model choice to set the position, velocity, and acceleration, solve for force.  This is achieved by variable defaults and equations
@component function MassSpringDamper(;name)

    pars = @parameters begin
        mass=1000.0
        gravity=0
        stiffness=1e6
        damping=1e3
        initial_position=0.0
    end

    vars = @variables begin
        s(t) = initial_position
        v(t) = 0
        a(t) = 0
        f(t), [guess=0]
    end

    systems = @named begin
        damper = Damper(; d=damping)
        body = Mass(;m=mass, g=gravity)
        spring = Spring(;k=stiffness) #TODO: remove need to specify pre-calculated force, let MTK solve this
        port_m = MechanicalPort()
        port_sd = MechanicalPort()        
    end

    eqs = [       

        s ~ body.s
        v ~ body.v
        a ~ body.a
        f ~ body.f + spring.f + damper.f

        connect(damper.flange_a, spring.flange_a, body.flange, port_m)
        connect(port_sd, spring.flange_b, damper.flange_b)
    ]

    return ODESystem(eqs, t, vars, pars; systems, name)
end

@kwdef mutable struct SystemParams
    gravity::Float64 = 0.0
    wheel::MassSpringDamperParams = MassSpringDamperParams(;mass=25, stiffness=1e2, damping=1e4, initial_position=0.5)
    car_and_suspension::MassSpringDamperParams = MassSpringDamperParams(;mass=1000, stiffness=1e4, damping=10, initial_position=1.0)
    seat::MassSpringDamperParams = MassSpringDamperParams(;mass=100, stiffness=1000, damping=1, initial_position=1.5)
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

Base.copy(x::SystemParams) = SystemParams(x.gravity, copy(x.wheel), copy(x.car_and_suspension), copy(x.seat), copy(x.road_data), copy(x.pid))

# INIT NOTE: gravity and initial_position are related using parameter_dependencies, and note defaults must also be set!!!
@component function System(; name)

    pars = @parameters begin
          gravity = 0
    end

    vars = []

    systems = @named begin
        seat = MassSpringDamper() # parameter dependancy: gravity
        car_and_suspension = MassSpringDamper() # parameter dependancy: gravity
        wheel = MassSpringDamper() # parameter dependancy: gravity
        road_data = Road()
        road = Position()
        force = Force()
        pid = Controller()
        err = Add(; k1=1, k2=-1) #makes a subtract
        set_point = Constant() # parameter dependancy: initial_position
        seat_pos = PositionSensor() # parameter dependancy: initial_position
        flip = Gain(; k=-1)
    end

    parameter_dependencies=[
        seat.gravity => gravity
        car_and_suspension.gravity => gravity
        wheel.gravity => gravity
    
        set_point.k=>seat.initial_position
        seat_pos.initial_position => seat.initial_position
        ]


    eqs = [
        
        # mechanical model
        connect(road.s, road_data.output)
        connect(road.flange, wheel.port_sd)
        connect(wheel.port_m, car_and_suspension.port_sd)
        connect(car_and_suspension.port_m, seat.port_sd)
        connect(seat.port_m, force.flange, seat_pos.flange)
        
        # controller        
        connect(err.input1, seat_pos.output)
        connect(err.input2, set_point.output)
        connect(pid.err_input, err.output)
        connect(pid.ctr_output, flip.input)
        connect(flip.output, force.f)        
    ]

    return ODESystem(eqs, t, vars, pars; systems, name, parameter_dependencies, defaults=parameter_dependencies)
end



# API -----------------

@mtkbuild sys = System()
prob = ODEProblem(sys, [], (0, 10); eval_expression = false, eval_module = @__MODULE__)

function show_params(params::SystemParams)
    display(params)
end

function duplicate_params(params::SystemParams)
    return copy(params)
end

function run(params::SystemParams, states = "road.s.u, wheel.body.s, car_and_suspension.body.s, seat.body.s")

    #BUG: see https://github.com/SciML/ModelingToolkit.jl/issues/2832
    prob′ = remake(prob; u0=Dict(), p=sys .=> params)
    sol = solve(prob′; dtmax=0.1)

    vars = [ModelingToolkit.getvar(sys, Symbol(replace(strip(state), "."=>"₊"))) for state in split(states, ',')]
    data = [sol.t]
    for var in vars
        push!(data, sol[var])
    end

    return hcat(data...) 
end

@setup_workload begin   
    @compile_workload begin
        params = SystemParams()
        run(params)
    end
end

end # module ActiveSuspensionModel





