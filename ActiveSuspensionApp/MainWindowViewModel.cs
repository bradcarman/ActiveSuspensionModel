using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;

namespace ActiveSuspensionApp
{
    

    public class MainWindowViewModel
    {
        public SystemParams SelectedSystemParams { get; set; }
        public MassSpringDamperView Wheel { get; set; }
        public MassSpringDamperView Car { get; set; }
        public MassSpringDamperView Seat { get; set; }

        public MainWindowViewModel()
        {
            IntPtr pars_ptr = Julia.jl_eval_string("ActiveSuspensionModel.SystemParams()");
            SelectedSystemParams = new SystemParams(pars_ptr, true);

            Wheel = new MassSpringDamperView(SelectedSystemParams.wheel, "Wheel");
            Car = new MassSpringDamperView(SelectedSystemParams.car_and_suspension, "Car");
            Seat = new MassSpringDamperView(SelectedSystemParams.seat, "Seat");

        }

    }
}
