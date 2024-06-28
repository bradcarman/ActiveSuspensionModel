using ActiveSuspensionModel: sys, prob, SystemParams
using DifferentialEquations
using ModelingToolkit.SymbolicIndexingInterface

solve(prob) #OK




prob′ = remake(prob; p=[sys.gravity => 9.807]) #ERROR: KeyError: key (0x1fb0168a, 0x68f1967e, 0xf4294b70, 0xdc8ef697, 0xdcd7675c) not found
sol = solve(prob′; dtmax=0.1)


setg = setp(prob, sys.gravity)
setg(prob, 9.87)
