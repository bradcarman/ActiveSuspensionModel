using System;
using System.Runtime.InteropServices;
using System.Threading.Tasks;


namespace ActiveSuspensionApp
{

    public static partial class Methods
    {

        public static void send_params(SystemParams pars)
        {

            IntPtr module = Julia.jl_eval_string("ActiveSuspensionModel");
            IntPtr send_params_sym = Julia.jl_symbol("send_params");
            IntPtr send_params_fun = Julia.jl_get_global(module, send_params_sym);
            IntPtr arg1 = pars.Pointer;

            Julia.RunFunction(send_params_fun, arg1);
        }

        public static double[,] run(SystemParams pars)
        {

            IntPtr module = Julia.jl_eval_string("ActiveSuspensionModel");
            IntPtr run_sym = Julia.jl_symbol("run");
            IntPtr run_fun = Julia.jl_get_global(module, run_sym);
            IntPtr arg1 = pars.Pointer;

            IntPtr ret = Julia.RunFunction(run_fun, arg1);

            return Julia.GetFloat64Matrix(ret);
        }


    }

}
