using Test
using ActiveSuspensionModel
using ModelingToolkit
using DifferentialEquations
# using CairoMakie

using ModelingToolkit: t_nounits as t
using ActiveSuspensionModel: sys, prob, SystemParams, run, System

@mtkbuild model = System()
params = SystemParams()
prb = ODEProblem(model, [], (0, 10), model .=> params)
sol = solve(prb; dtmax=0.1)

