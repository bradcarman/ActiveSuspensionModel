using ModelingToolkitDesigner
using ActiveSuspensionModel: System
using ModelingToolkit



@named model = System()

# ModelingToolkitDesigner.add_color(model.wheel.port_m, :yellowgreen)

path = joinpath(@__DIR__, "design")
design = ODESystemDesign(model, path)
ModelingToolkitDesigner.view(design)

using CairoMakie
CairoMakie.set_theme!(Theme(;fontsize=12))
fig = ModelingToolkitDesigner.view(design, false)
save(joinpath(@__DIR__, "model.png"), fig; resolution=(800,800))