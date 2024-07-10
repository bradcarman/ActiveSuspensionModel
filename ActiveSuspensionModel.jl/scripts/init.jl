using ModelingToolkit: t_nounits as t, D_nounits as D
using ModelingToolkit
using DifferentialEquations
using ModelingToolkitStandardLibrary.Blocks: RealInput, RealOutput, Add, Constant

@connector MechanicalPort begin
    v(t), [guess=0.0]
    f(t), [connect = Flow, guess=0.0]
end

@mtkmodel Fixed begin
    @components begin
        flange = MechanicalPort()
    end
    @equations begin
        flange.v ~ 0
    end
end

@component function Mass(; name, m, g=0, x_0=0)
    pars = @parameters begin
        x_0=x_0
        m=m
        g=g
    end
    vars = @variables begin
        x(t)=x_0
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

        D(x) ~ v
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

@mtkmodel Damper begin
    @parameters begin
        d
    end
    @variables begin
        v(t)=0.0
        f(t)=0.0
    end

    @components begin
        flange_a = MechanicalPort()
        flange_b = MechanicalPort()
    end

    @equations begin
        v ~ flange_a.v - flange_b.v
        f ~ v * d
        flange_a.f ~ +f
        flange_b.f ~ -f
    end
end

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

@component function Position(;name)
    vars = []

    systems = @named begin
        flange = MechanicalPort()
        s = RealInput()
    end

    eqs = [
        D(s.u) ~ flange.v
    ]

    ODESystem(eqs, t, vars, []; name, systems)
end

@mtkmodel Force begin
    @components begin
        flange = MechanicalPort()
        f = RealInput()
    end

    @equations begin
        flange.f ~ -f.u
    end
end

@component function Controller(; name)
    
    pars = @parameters begin
        kp = 0
        ki = 1
        kd = 1
    end

    vars = @variables begin
        x(t), [guess = 0]
        dx(t), [guess = 0]
        ddx(t), [guess = 0]
        y(t), [guess = 0]
        dy(t), [guess = 0]
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

@mtkmodel PositionSensor begin
    @components begin
        flange = MechanicalPort()
        output = RealOutput()
    end
    @parameters begin
        initial_position=0.0
    end

    @variables begin
        s(t)=initial_position
    end

    @equations begin
        D(s) ~ flange.v
        output.u ~ s
        flange.f ~ 0.0
    end
end

@mtkmodel System2 begin
    @components begin
        mass2 = Mass(;m=100, g=-9.807)
        spring2 = Spring(;k=100)
        damp2 = Damper(;d=100)
        mass1 = Mass(;m=100, g=-9.807)
        spring1 = Spring(;k=100)
        damp1 = Damper(;d=100)
        road_data = Road()
        road = Position()
        force = Force()
        pid = Controller()
        err = Add()
        seat_pos = PositionSensor()
        set_point = Constant(k=0.0)
    end
    @equations begin
        connect(spring1.flange_a, damp1.flange_a, mass1.flange, seat_pos.flange, force.flange)
        connect(spring1.flange_b, damp1.flange_b, spring2.flange_a, mass2.flange, damp2.flange_a)
        connect(spring2.flange_b, damp2.flange_b, road.flange)
        connect(road_data.output, road.s)


        # controller        
        connect(err.input1, seat_pos.output)
        connect(err.input2, set_point.output)
        connect(pid.err_input, err.output)
        connect(pid.ctr_output, force.f)

    end
end

@mtkbuild model = System2()
prb = ODEProblem(model, [], (0,1))
isys = ModelingToolkit.generate_initializesystem(model)

sol = solve(prb)

sol(0.0; idxs=model.spring1.delta_s)
sol(0.0; idxs=model.spring2.delta_s)
sol(0.0; idxs=model.spring1.f)
sol(0.0; idxs=model.spring2.f)
sol(0.0; idxs=model.mass1.f)
sol(0.0; idxs=model.mass1.a)
sol(0.0; idxs=model.pid.y)
sol(0.0; idxs=model.pid.dy)
sol(0.0; idxs=model.pid.x)
sol(0.0; idxs=model.pid.dx)
sol(0.0; idxs=model.pid.ddx)




using CairoMakie
lines(sol.t, sol[model.mass1.x])
lines(sol.t, sol[model.mass2.x])
