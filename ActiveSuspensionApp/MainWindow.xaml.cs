﻿using OxyPlot.Series;
using System.Collections.ObjectModel;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace ActiveSuspensionApp
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();

            Julia.StartJulia();

            //DEBUG
            Julia.jl_eval_string("using ActiveSuspensionModel");

            //RELEASE

            // --------------

            //IntPtr pars_ptr = Julia.jl_eval_string("ActiveSuspensionModel.SystemParams()");
            //SystemParams pars = new SystemParams(pars_ptr, true);






            //Julia.jl_eval_string("Base._start()");

            Data = new MainWindowViewModel();
            this.DataContext = Data;
        }

        
        private MainWindowViewModel Data { get; set; }

        private void Button_SendParameters(object sender, RoutedEventArgs e)
        {
            if (Data.SelectedSimulation != null)
                Methods.send_params(Data.SelectedSimulation.Parameters);

        }

        private void Button_RunModel(object sender, RoutedEventArgs e)
        {
            if (Data.SelectedSimulation != null)
            {
                double[,] data = Methods.run(Data.SelectedSimulation.Parameters);

                Data.PlotModel.Series.Clear();

                int r = data.GetLength(0);
                int c = data.GetLength(1);

                for (int i = 1; i < c; i++)
                {
                    LineSeries series = new LineSeries();
                    Data.PlotModel.Series.Add(series);
                    for (int j = 0; j < r; j++)
                    {
                        series.Points.Add(new OxyPlot.DataPoint(j, data[j, i]));
                    }
                }

                Data.PlotModel.InvalidatePlot(true);
            }
        }

    }
}