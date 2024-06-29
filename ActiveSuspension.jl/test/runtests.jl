using ActiveSuspension: run
using ActiveSuspensionModel: SystemParams

params = SystemParams();
@time "run1" run(params);
@time "run2" run(params);