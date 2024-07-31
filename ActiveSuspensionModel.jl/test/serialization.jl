using ActiveSuspensionModel: SystemParams, run

params = SystemParams();

@time "run 1" run(params);
@time "run 2" run(params);