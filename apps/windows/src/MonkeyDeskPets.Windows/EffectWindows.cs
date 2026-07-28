using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;
using System.Windows.Threading;

namespace MonkeyDeskPets.Windows;

internal sealed class FoodWindow : Window
{
    internal Point Center => new(Left + Width / 2, Top + Height / 2);

    internal FoodWindow(Point location)
    {
        Width = 50;
        Height = 42;
        Left = location.X - Width / 2;
        Top = location.Y - Height / 2;
        AllowsTransparency = true;
        Background = Brushes.Transparent;
        WindowStyle = WindowStyle.None;
        ShowInTaskbar = false;
        Topmost = true;
        IsHitTestVisible = false;

        var canvas = new Canvas();
        var bowl = new Border
        {
            Width = 46,
            Height = 20,
            CornerRadius = new CornerRadius(4, 4, 12, 12),
            Background = new SolidColorBrush(Color.FromRgb(55, 125, 205)),
            BorderBrush = Brushes.Navy,
            BorderThickness = new Thickness(2)
        };
        Canvas.SetTop(bowl, 17);
        canvas.Children.Add(bowl);
        foreach (var (x, y) in new[] { (9d, 10d), (19d, 5d), (29d, 9d), (37d, 6d) })
        {
            var kibble = new Ellipse
            {
                Width = 9,
                Height = 7,
                Fill = new SolidColorBrush(Color.FromRgb(126, 76, 34)),
                Stroke = new SolidColorBrush(Color.FromRgb(76, 43, 18)),
                StrokeThickness = 1
            };
            Canvas.SetLeft(kibble, x);
            Canvas.SetTop(kibble, y);
            canvas.Children.Add(kibble);
        }
        Content = canvas;
    }
}

internal sealed class PlacementWindow : Window
{
    internal event Action<Point>? PositionChosen;

    internal PlacementWindow()
    {
        Left = SystemParameters.VirtualScreenLeft;
        Top = SystemParameters.VirtualScreenTop;
        Width = SystemParameters.VirtualScreenWidth;
        Height = SystemParameters.VirtualScreenHeight;
        WindowStyle = WindowStyle.None;
        AllowsTransparency = true;
        Background = new SolidColorBrush(Color.FromArgb(2, 0, 0, 0));
        Cursor = System.Windows.Input.Cursors.Cross;
        ShowInTaskbar = false;
        Topmost = true;
        MouseLeftButtonDown += (_, eventArgs) =>
        {
            var local = eventArgs.GetPosition(this);
            PositionChosen?.Invoke(new Point(Left + local.X, Top + local.Y));
            Close();
        };
        KeyDown += (_, eventArgs) =>
        {
            if (eventArgs.Key == System.Windows.Input.Key.Escape)
                Close();
        };
    }
}

internal sealed class ExplosionWindow : Window
{
    internal ExplosionWindow(Point location)
    {
        Width = 110;
        Height = 110;
        Left = location.X - Width / 2;
        Top = location.Y - Height / 2;
        AllowsTransparency = true;
        Background = Brushes.Transparent;
        WindowStyle = WindowStyle.None;
        ShowInTaskbar = false;
        Topmost = true;
        IsHitTestVisible = false;
        Content = new TextBlock
        {
            Text = "💥",
            FontSize = 78,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center
        };
        Loaded += (_, _) =>
        {
            var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(420) };
            timer.Tick += (_, _) =>
            {
                timer.Stop();
                Close();
            };
            timer.Start();
        };
    }
}
