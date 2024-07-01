using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;
using OxyPlot;
using OxyPlot.Axes;
using OxyPlot.Series;


namespace ActiveSuspensionApp
{
    

    public class MainWindowViewModel : INotifyPropertyChanged
    {

        public Visibility ParametersVisibility { get; set; } = Visibility.Hidden;

        SimulationView? mSelectedSimulation = null;
        public SimulationView? SelectedSimulation 
        {
            get { return mSelectedSimulation; }
            set 
            { 
                mSelectedSimulation = value;
                RunSimulationCommand.RaiseCanExecuteChanged();
                ShowParametersCommand.RaiseCanExecuteChanged();

                ParametersVisibility = mSelectedSimulation == null ? Visibility.Hidden : Visibility.Visible;
                OnPropertyChanged("ParametersVisibility");
                OnPropertyChanged("SelectedSimulation");
            } 
        }
        public ObservableCollection<SimulationView> Simulations { get; set; }

        public PlotModel PlotModel { get; private set; }

        public OperationCommand AddSimulationCommand { get; set; }
        public OperationCommand RunSimulationCommand { get; set; }
        public OperationCommand ShowParametersCommand { get; set; }

        public MainWindowViewModel()
        {

            PlotModel = new PlotModel();
            PlotModel.Axes.Add(new LinearAxis { Position = AxisPosition.Bottom, Title = "time [s]", MajorGridlineStyle = LineStyle.Solid, MinorGridlineStyle = LineStyle.Dot });
            PlotModel.Axes.Add(new LinearAxis { Position = AxisPosition.Left, Title= "y position [m]", MajorGridlineStyle = LineStyle.Solid, MinorGridlineStyle = LineStyle.Dot });

            Simulations = new ObservableCollection<SimulationView>();

            AddSimulationCommand = new OperationCommand((o) => DoAddSimulation(), (o) => true);
            RunSimulationCommand = new OperationCommand((o) => DoRunSimulation(), (o) => IsSimulationSelected());
            ShowParametersCommand = new OperationCommand((o) => DoShowParameters(), (o) => IsSimulationSelected());
        }

        public void DoAddSimulation()
        {
            IntPtr pars_ptr = Julia.jl_eval_string("ActiveSuspensionModel.SystemParams()");
            SystemParams mSystemParams = new SystemParams(pars_ptr, true);
            Simulations.Add(new SimulationView(mSystemParams, Simulations.Count+1));
            SelectedSimulation = Simulations.Last();
            ParametersVisibility = Visibility.Visible;
            OnPropertyChanged("Simulations");
        }


        public bool IsSimulationSelected()
        {
            return SelectedSimulation != null;
        }

        public void DoRunSimulation()
        {
            if (SelectedSimulation != null)
            {
                double[,] data = Methods.run(SelectedSimulation.Parameters);

                PlotModel.Series.Clear();

                int r = data.GetLength(0);
                int c = data.GetLength(1);

                for (int i = 1; i < c; i++)
                {
                    LineSeries series = new LineSeries { Color = PlotModel.DefaultColors[SelectedSimulation.Id-1] };
                    PlotModel.Series.Add(series);
                    for (int j = 0; j < r; j++)
                    {
                        series.Points.Add(new OxyPlot.DataPoint(data[j,0], data[j, i]));
                    }
                }

                PlotModel.InvalidatePlot(true);
            }
        }

        public void DoShowParameters()
        {
            if (SelectedSimulation != null)
                Methods.send_params(SelectedSimulation.Parameters);
        }


        public event PropertyChangedEventHandler? PropertyChanged;

        protected void OnPropertyChanged([CallerMemberName] string name = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
        }

    }
}
