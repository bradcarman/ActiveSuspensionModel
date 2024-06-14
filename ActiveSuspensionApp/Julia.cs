using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace ActiveSuspensionApp
{
    public static class Julia
    {



        // IMPORTS ----------------------------------------------------
        // windows 
        [DllImport("kernel32.dll")]
        static extern bool SetDllDirectory(string pathName);


        // julia
        [DllImport(@"libjulia.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
        public static extern IntPtr jl_symbol(string name);

        [DllImport(@"libjulia.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
        public static extern IntPtr jl_get_global(IntPtr module, IntPtr symbol);

        [DllImport(@"libjulia.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
        private static extern void jl_init_with_image__threading(string julia_bindir, string image_relative_path);

        [DllImport(@"libjulia.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
        public static extern IntPtr jl_eval_string(string str);

        [DllImport(@"libjulia.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
        public static extern IntPtr jl_call0(IntPtr function);

        [DllImport(@"libjulia.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
        public static extern IntPtr jl_call1(IntPtr function, IntPtr arg1);

        [DllImport(@"libjulia.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
        public static extern IntPtr jl_call2(IntPtr function, IntPtr arg1, IntPtr arg2);

        [DllImport(@"libjulia.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
        public static extern IntPtr jl_call3(IntPtr function, IntPtr arg1, IntPtr arg2, IntPtr arg3);

        //[DllImport(@"libjulia.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
        //public static extern IntPtr jl_new_struct(IntPtr type, IntPtr val);

        [DllImport(@"libjulia.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
        public static extern IntPtr jl_call(IntPtr function, IntPtr args, int nargs);


        // GC ---------------------------------------------
        public static void gc_push(IntPtr var)
        {
            jl_setindex(refs, var, var);
        }

        public static void gc_pop(IntPtr var)
        {
           jl_delete(refs, var);
        }

        // FUNCTIONS -------------------------------------
        public static IntPtr base_module;
        public static IntPtr setindex_sym;
        public static IntPtr setindex_fun;
        public static IntPtr delete_sym;
        public static IntPtr delete_fun;
        public static IntPtr refs;
        //public static IntPtr refval = jl_eval_string("Base.RefValue{Any}");

        public static void jl_setindex(IntPtr collection, IntPtr key, IntPtr value)
        {
            jl_call3(setindex_fun, collection, key, value);
        }

        public static void jl_delete(IntPtr collection, IntPtr key)
        {
            jl_call2(delete_fun, collection, key);
        }


        // STARTUP -------------------------------------
        static string mBinPath = @"C:\Programs\julia-1.10.4\bin";
        static string mSysImg = "./../lib/julia/sys.dll";
        static string mLoadPath = @"C:\Work\Packages\ActiveSuspension\ActiveSuspensionModel.jl";
        static string mDepotPath = @"C:\Users\bradl\.julia";

        public static void StartJulia()
        {


            if (mDepotPath != null)
                Environment.SetEnvironmentVariable("JULIA_DEPOT_PATH", mDepotPath);

            if (mLoadPath != null)
                Environment.SetEnvironmentVariable("JULIA_LOAD_PATH", mLoadPath);

            //NOTE: This appears to help, if the Path variable is set to a different version of Julia then the version loading from Julia installer,
            //      this will crash, so SetDllDirectory ensures the libjulia.dll will be the correct one I guess
            SetDllDirectory(mBinPath);

            jl_init_with_image__threading(mBinPath, mSysImg);


            base_module = jl_eval_string("Base");
            setindex_sym = jl_symbol("setindex!");
            setindex_fun = jl_get_global(base_module, setindex_sym);
            delete_sym = jl_symbol("delete!");
            delete_fun = jl_get_global(base_module, delete_sym);
            refs = jl_eval_string("refs = IdDict()");


    }
    }
}
