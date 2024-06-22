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

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            
            Methods.send_params(Data.SelectedSystemParams);
            
        }
    }
}