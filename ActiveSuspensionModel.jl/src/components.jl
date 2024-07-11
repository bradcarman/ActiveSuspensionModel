
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

# -------------------------------------------------------------------

@mtkmodel Gain begin
    @parameters begin
        k, [description = "Gain"]
    end
    @components begin
        input = RealInput()
        output = RealOutput()        
    end
    @equations begin
        output.u ~ k * input.u
    end
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

@component function Mass(; name, m, g=0, s=0)
    pars = @parameters begin
        m=m
        g=g
    end
    vars = @variables begin
        s(t)=s
        v(t)=0
        f(t)=-m*g
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

@component function Spring(; name, k, f)
    pars = @parameters begin
        k = k
    end
    vars = @variables begin
        delta_s(t)=f/k
        f(t)=f
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


# ----------------------------------