using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;
using OxyPlot;
using OxyPlot.Series;


namespace ActiveSuspensionApp
{
    

    public class MainWindowViewModel : INotifyPropertyChanged
    {
        
        private SystemParams mSystemParams { get; set; }
        public SystemView SelectedSystemParams { get; set; }

        public PlotModel PlotModel { get; private set; }

        public MainWindowViewModel()
        {
            IntPtr pars_ptr = Julia.jl_eval_string("ActiveSuspensionModel.SystemParams()");
            mSystemParams = new SystemParams(pars_ptr, true);
            SelectedSystemParams = new SystemView(mSystemParams);
            OnPropertyChanged("SelectedSystemParams");

            PlotModel = new PlotModel { Title = "Example 1" };
            PlotModel.Series.Add(new FunctionSeries(Math.Cos, 0, 10, 0.1, "cos(x)"));
        }

        public event PropertyChangedEventHandler? PropertyChanged;

        protected void OnPropertyChanged([CallerMemberName] string name = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
        }

    }
}
