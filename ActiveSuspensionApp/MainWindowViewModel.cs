using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
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


        public SimulationView? SelectedSimulation { get; set; } = null;
        public ObservableCollection<SimulationView> Simulations { get; set; }

        public PlotModel PlotModel { get; private set; }

        public OperationCommand AddSimulationCommand { get; set; }

        public MainWindowViewModel()
        {
            

            PlotModel = new PlotModel();
            Simulations = new ObservableCollection<SimulationView>();

            AddSimulationCommand = new OperationCommand((o) => AddSimulation(), (o) => true);

        }

        public void AddSimulation()
        {
            IntPtr pars_ptr = Julia.jl_eval_string("ActiveSuspensionModel.SystemParams()");
            SystemParams mSystemParams = new SystemParams(pars_ptr, true);
            Simulations.Add(new SimulationView(mSystemParams, "simulation 1"));
            SelectedSimulation = Simulations.Last();

            OnPropertyChanged("Simulations");
            OnPropertyChanged("SelectedSimulation");
        }

        public event PropertyChangedEventHandler? PropertyChanged;

        protected void OnPropertyChanged([CallerMemberName] string name = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
        }

    }
}
