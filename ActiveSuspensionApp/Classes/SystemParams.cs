using System;
using System.Runtime.InteropServices;

namespace ActiveSuspensionApp
{
	public struct SystemParamsType
	{
		public double gravity;
		public IntPtr wheel;
		public IntPtr car_and_suspension;
		public IntPtr seat;
		public IntPtr road_data;
		public IntPtr pid;
	}
	
	public partial class SystemParams
	{
		IntPtr pointer = IntPtr.Zero;
		
		public IntPtr Pointer
		{
			get
			{
				if (pointer == IntPtr.Zero)
				{
					IntPtr ptr = Marshal.AllocHGlobal(Marshal.SizeOf<SystemParamsType>());
					Marshal.StructureToPtr(Data, ptr, true);
					IntPtr send = Marshal.AllocHGlobal(Marshal.SizeOf<IntPtr>());
					Marshal.WriteIntPtr(send, ptr);
					pointer = Julia.jl_eval_string(String.Format("p = Ptr{{Ptr{{ActiveSuspensionModel.SystemParams}}}}({0}); t = unsafe_load(unsafe_load(p)); t", send.ToInt64()));
					
					
					Julia.gc_push(pointer);
				}
				
				return pointer;
			}
			
		}
		
		public SystemParamsType Data;
		private bool IsProtected = false;
		
		public SystemParams(IntPtr ptr, bool protect = false)
		{
			pointer = ptr;
			if (protect)
			{
				IsProtected=true;
				Julia.gc_push(pointer);
			}
			
			Data = Marshal.PtrToStructure<SystemParamsType>(ptr);
			gravity = Data.gravity;
			wheel = new MassSpringDamperParams(Data.wheel);
			car_and_suspension = new MassSpringDamperParams(Data.car_and_suspension);
			seat = new MassSpringDamperParams(Data.seat);
			road_data = new RoadParams(Data.road_data);
			pid = new ControllerParams(Data.pid);
		}
		
		public double gravity {
			get { return Data.gravity; }
			set
			{
				Data.gravity = value;
				Julia.RunFunction(Julia.setproperty_fun, Pointer, Julia.jl_symbol("gravity"), Julia.jl_box_float64(value) );
			}
		}
		
		public MassSpringDamperParams wheel { get; set; }
		public MassSpringDamperParams car_and_suspension { get; set; }
		public MassSpringDamperParams seat { get; set; }
		public RoadParams road_data { get; set; }
		public ControllerParams pid { get; set; }
		
		~SystemParams() // finalizer
		{
			if (IsProtected & (pointer != IntPtr.Zero))
			{
				Console.WriteLine("Releasing SystemParams with pointer: " + pointer.ToString());
				Julia.gc_pop(pointer);
			}
		}
	}
	
}
