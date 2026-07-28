using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Shapes;
using WpfPoint = System.Windows.Point;

namespace MonkeyDeskPets.Windows;

internal sealed class FoodWindow : Window
{
    internal WpfPoint Center => new(Left + Width / 2, Top + Height / 2);

    internal FoodWindow(WpfPoint location)
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
    internal event Action<WpfPoint>? PositionChosen;

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
            PositionChosen?.Invoke(new WpfPoint(Left + local.X, Top + local.Y));
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
    internal ExplosionWindow(WpfPoint location)
    {
        Width = 130;
        Height = 130;
        Left = location.X - Width / 2;
        Top = location.Y - Height / 2;
        AllowsTransparency = true;
        Background = Brushes.Transparent;
        WindowStyle = WindowStyle.None;
        ShowInTaskbar = false;
        Topmost = true;
        IsHitTestVisible = false;

        const double center = 65;
        const double outerRadius = 59.8;
        const double innerRadius = 28.7;
        const int rayCount = 18;
        var points = new PointCollection();
        for (var index = 0; index < rayCount * 2; index++)
        {
            var angle = index * Math.PI / rayCount - Math.PI / 2;
            var radius = index % 2 == 0 ? outerRadius : innerRadius;
            points.Add(new WpfPoint(
                center + Math.Cos(angle) * radius,
                center + Math.Sin(angle) * radius
            ));
        }

        var canvas = new Canvas { Width = 130, Height = 130 };
        canvas.Children.Add(new Polygon
        {
            Points = points,
            Fill = new SolidColorBrush(Color.FromRgb(255, 149, 0))
        });

        var yellowCore = new Ellipse
        {
            Width = innerRadius * 2,
            Height = innerRadius * 2,
            Fill = new SolidColorBrush(Color.FromRgb(255, 204, 0))
        };
        Canvas.SetLeft(yellowCore, center - innerRadius);
        Canvas.SetTop(yellowCore, center - innerRadius);
        canvas.Children.Add(yellowCore);

        var whiteCore = new Ellipse
        {
            Width = 20,
            Height = 20,
            Fill = new SolidColorBrush(Color.FromArgb(230, 255, 255, 255))
        };
        Canvas.SetLeft(whiteCore, center - 10);
        Canvas.SetTop(whiteCore, center - 6);
        canvas.Children.Add(whiteCore);
        Content = canvas;

        Loaded += (_, _) =>
        {
            var fade = new DoubleAnimation
            {
                From = 1,
                To = 0,
                Duration = TimeSpan.FromMilliseconds(650),
                EasingFunction = new QuadraticEase { EasingMode = EasingMode.EaseOut }
            };
            fade.Completed += (_, _) => Close();
            BeginAnimation(OpacityProperty, fade);
        };
    }
}
