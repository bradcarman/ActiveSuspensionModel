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

            LineRoad = new LineSeries() { Color = OxyColors.Black };
            PlotModel.Series.Add(LineRoad);

            Simulations = new ObservableCollection<SimulationView>();

            AddSimulationCommand = new OperationCommand((o) => DoAddSimulation(), (o) => true);
            RunSimulationCommand = new OperationCommand((o) => DoRunSimulation(), (o) => IsSimulationSelected());
            ShowParametersCommand = new OperationCommand((o) => DoShowParameters(), (o) => IsSimulationSelected());
        }

        public void DoAddSimulation()
        {
            IntPtr pars_ptr = Julia.jl_eval_string("ActiveSuspensionModel.SystemParams()");
            SystemParams mSystemParams = new SystemParams(pars_ptr, true);
            int id = Simulations.Count + 1;
            OxyColor color = PlotModel.DefaultColors[id];
            SimulationView simulation = new SimulationView(mSystemParams, id, color);
            simulation.VisibleChanged += Simulation_VisibleChanged;
            
            Simulations.Add(simulation);
            PlotModel.Series.Add(simulation.LineWheel);
            PlotModel.Series.Add(simulation.LineCar);
            PlotModel.Series.Add(simulation.LineSeat);

            SelectedSimulation = Simulations.Last();
            ParametersVisibility = Visibility.Visible;
            OnPropertyChanged("Simulations");
        }

        private void Simulation_VisibleChanged(object? sender, EventArgs e)
        {
            PlotModel.InvalidatePlot(false);
        }

        private LineSeries LineRoad { get; set; }

        public bool IsSimulationSelected()
        {
            return SelectedSimulation != null;
        }

        public void DoRunSimulation()
        {
            if (SelectedSimulation != null)
            {
                double[,] data = Methods.run(SelectedSimulation.Parameters);

                LineRoad.Points.Clear();
                SelectedSimulation.LineWheel.Points.Clear();
                SelectedSimulation.LineCar.Points.Clear();
                SelectedSimulation.LineSeat.Points.Clear();

                int r = data.GetLength(0);

                for (int j = 0; j < r; j++)
                {
                    LineRoad.Points.Add(new OxyPlot.DataPoint(data[j, 0], data[j, 1]));
                    SelectedSimulation.LineWheel.Points.Add(new OxyPlot.DataPoint(data[j, 0], data[j, 2]));
                    SelectedSimulation.LineCar.Points.Add(new OxyPlot.DataPoint(data[j, 0], data[j, 3]));
                    SelectedSimulation.LineSeat.Points.Add(new OxyPlot.DataPoint(data[j, 0], data[j, 4]));
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
