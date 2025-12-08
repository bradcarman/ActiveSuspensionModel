module ActiveSuspensionModel
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using DifferentialEquations
using RuntimeGeneratedFunctions
using PrecompileTools
using ModelingToolkitParameters
RuntimeGeneratedFunctions.init(@__MODULE__)

# base model components
include("components.jl")

# top level model 
# -----------------------------------------------------
Base.@kwdef mutable struct RoadParams <: Params
    # parameters
    bump::Real = 0.2
    freq::Real = 0.5
    offset::Real = 1.0
    loop::Real = 10
end


# TODO: replace with TOML.print
# function Base.show(io::IO, ::MIME"text/plain", x::RoadParams)
# 	println(io, "[RoadParams] \n bump=$(x.bump) \n freq=$(x.freq) \n offset=$(x.offset) \n loop=$(x.loop)")
# end

#y data as a function of time (assuming car is traveling at constant speed of 15m/s)
@component function Road(; name)
    
    systems = @named begin
        output = RealOutput()
    end
    
    pars = @parameters begin
        bump
        freq
        offset
        loop
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


Base.@kwdef mutable struct ControllerParams <: Params
    # parameters
    kp::Real = 1.0
    ki::Real = 0.2
    kd::Real = 20.0
end

@component function Controller(; name)
    
    pars = @parameters begin
        kp = 1
        ki = 1
        kd = 1
    end

    vars = @variables begin
        x(t)
        dx(t)
        ddx(t)
        y(t)
        dy(t)
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


Base.@kwdef mutable struct MassSpringDamperParams <: Params
    # systems
    damper::DamperParams = DamperParams()
    body::MassParams = MassParams()
    spring::SpringParams = SpringParams()
end

@component function MassSpringDamper(;name)

    systems = @named begin
        damper = Damper()
        body = Mass()
        spring = Spring()
        port_m = MechanicalPort()
        port_sd = MechanicalPort()        
    end

    eqs = [       
        connect(damper.flange_a, spring.flange_a, body.flange, port_m)
        connect(port_sd, spring.flange_b, damper.flange_b)
    ]

    return System(eqs, t, [], []; systems, name)
end

#=
    wheel::MassSpringDamperParams = MassSpringDamperParams(;mass=25, stiffness=1e2, damping=1e4, initial_position=0.5)
    car_and_suspension::MassSpringDamperParams = MassSpringDamperParams(;mass=1000, stiffness=1e4, damping=10, initial_position=1.0)
    seat::MassSpringDamperParams = MassSpringDamperParams(;mass=100, stiffness=1000, damping=1, initial_position=1.5)
=#


Base.@kwdef mutable struct ModelParams <: Params
    # parameters
    g::Real = -9.807
    # systems
    seat::MassSpringDamperParams = MassSpringDamperParams(;body=MassParams(m=100), spring=SpringParams(k=1000), damper=DamperParams(d=1))
    car_and_suspension::MassSpringDamperParams = MassSpringDamperParams(;body=MassParams(m=1000), spring=SpringParams(k=1e4), damper=DamperParams(d=10))
    wheel::MassSpringDamperParams = MassSpringDamperParams(;body=MassParams(m=25), spring=SpringParams(k=1e2), damper=DamperParams(d=1e4))
    road_data::RoadParams = RoadParams()
    pid::ControllerParams = ControllerParams()
    err::AddParams = AddParams(k1=1,k2=-1)
    set_point::ConstantParams = ConstantParams()
    flip::GainParams = GainParams(k=-1)
end



@component function Model(; name)

    systems = @named begin
        seat = MassSpringDamper()
        car_and_suspension = MassSpringDamper()
        wheel = MassSpringDamper()
        road_data = Road()
        road = Position()
        force = Force()
        pid = Controller()
        err = Add() 
        set_point = Constant()
        seat_pos = PositionSensor()
        flip = Gain()
    end

    eqs = [
        
        # mechanical model
        connect(road.s, road_data.output)
        connect(road.flange, wheel.port_sd)
        connect(wheel.port_m, car_and_suspension.port_sd)
        connect(car_and_suspension.port_m, seat.port_sd, force.flange_a)
        connect(seat.port_m, force.flange_b, seat_pos.flange)
        
        # controller        
        connect(err.input1, seat_pos.output)
        connect(err.input2, set_point.output)
        connect(pid.err_input, err.output)
        connect(pid.ctr_output, flip.input)
        connect(flip.output, force.f)        
    ]

    return System(eqs, t, [], []; systems, name)
end


Base.@kwdef mutable struct InverseModelParams <: Params
    # parameters
    g::Real = -9.807
    # systems
    seat::MassSpringDamperParams = MassSpringDamperParams(damper = DamperParams(d = 1), spring = SpringParams(k=1e3), body = MassParams(m=100, g=-9.807))
    car_and_suspension::MassSpringDamperParams = MassSpringDamperParams(damper = DamperParams(d = 10), spring = SpringParams(k=1e4), body = MassParams(m=1000, g=-9.807))
    wheel::MassSpringDamperParams = MassSpringDamperParams(damper = DamperParams(d = 1e4), spring = SpringParams(k=1e2), body = MassParams(m=25, g=-9.807))
    road_data::RoadParams = RoadParams()
    set_point::ConstantParams = ConstantParams()
    flip::GainParams = GainParams()
end

@component function InverseModel(; name)

    systems = @named begin
        seat = MassSpringDamper()
        car_and_suspension = MassSpringDamper()
        wheel = MassSpringDamper()
        road_data = Road()
        road = Position()
        force = Force()
        set_point = Constant()
        seat_pos = PositionInput()
        flip = Gain()

        unknown = Unknown()
    end

    eqs = [
        
        # mechanical model
        connect(road.s, road_data.output)
        connect(road.flange, wheel.port_sd)
        connect(wheel.port_m, car_and_suspension.port_sd)
        connect(car_and_suspension.port_m, seat.port_sd)
        connect(seat.port_m, force.flange, seat_pos.flange)
        
        # controller        
        connect(set_point.output, seat_pos.input)
        connect(unknown.output, flip.input)
        connect(flip.output, force.f)        
    ]

    return System(eqs, t, [], []; systems, name)
end




# API -----------------
# @mtkbuild sys = System()
# initialization_eqs = [

#     sys.seat.body.s ~ 1.5
#     sys.seat.body.v ~ 0.0
#     sys.seat.body.a ~ 0.0

#     sys.car_and_suspension.body.s ~ 1.0
#     sys.car_and_suspension.body.v ~ 0.0
#     sys.car_and_suspension.body.a ~ 0.0

#     sys.wheel.body.s ~ 0.5
#     sys.wheel.body.v ~ 0.0
#     sys.wheel.body.a ~ 0.0

#     sys.pid.y ~ 0.0
# ]

# prob = ODEProblem(sys, [], (0, 10); eval_expression = false, eval_module = @__MODULE__, initialization_eqs)


end # module ActiveSuspensionModel





