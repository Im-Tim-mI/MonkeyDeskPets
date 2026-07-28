using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace MonkeyDeskPets.Windows;

internal enum Pose
{
    CrawlA = 0,
    CrawlB = 1,
    Climb = 2,
    Hang = 3,
    Crouch = 4,
    Leap = 5,
    Sit = 6,
    Sleep = 7
}

internal sealed class PetWindow : Window
{
    private const double DragThreshold = 6;
    private readonly Image sprite = new() { Stretch = Stretch.Uniform };
    private readonly Border speech;
    private Point mouseDownScreen;
    private Point windowDown;
    private bool pointerDown;
    private bool dragging;

    internal double VelocityX { get; set; }
    internal double VelocityY { get; set; }
    internal bool FacingRight { get; set; } = true;
    internal bool IsBusy { get; set; }
    internal bool IsDadLanding { get; set; }
    internal Point? FoodTarget { get; set; }
    internal Action<PetWindow, bool>? DragStateChanged { get; set; }

    internal PetWindow()
    {
        Width = 156;
        Height = 167;
        AllowsTransparency = true;
        Background = Brushes.Transparent;
        WindowStyle = WindowStyle.None;
        ResizeMode = ResizeMode.NoResize;
        ShowInTaskbar = false;
        Topmost = true;

        var root = new Grid();
        sprite.RenderTransformOrigin = new Point(0.5, 0.5);
        root.Children.Add(sprite);

        speech = new Border
        {
            Background = Brushes.White,
            BorderBrush = Brushes.Black,
            BorderThickness = new Thickness(2),
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(12, 5, 12, 5),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Top,
            Visibility = Visibility.Collapsed,
            Child = new TextBlock
            {
                Text = L.T("爸", "Dad"),
                FontSize = 22,
                FontWeight = FontWeights.Bold,
                Foreground = Brushes.Black
            }
        };
        root.Children.Add(speech);
        Content = root;

        MouseLeftButtonDown += OnMouseDown;
        MouseMove += OnMouseMove;
        MouseLeftButtonUp += OnMouseUp;
    }

    internal void SetFrame(BitmapSource frame, bool faceRight)
    {
        sprite.Source = frame;
        sprite.RenderTransform = new ScaleTransform(faceRight ? 1 : -1, 1);
        if (Opacity < 1)
            Opacity = 1;
    }

    internal void ShowSpeech(bool show) => speech.Visibility =
        show ? Visibility.Visible : Visibility.Collapsed;

    private void OnMouseDown(object sender, MouseButtonEventArgs e)
    {
        pointerDown = true;
        dragging = false;
        mouseDownScreen = PointToScreen(e.GetPosition(this));
        windowDown = new Point(Left, Top);
        CaptureMouse();
        e.Handled = true;
    }

    private void OnMouseMove(object sender, MouseEventArgs e)
    {
        if (!pointerDown || e.LeftButton != MouseButtonState.Pressed)
            return;

        var current = PointToScreen(e.GetPosition(this));
        var dx = current.X - mouseDownScreen.X;
        var dy = current.Y - mouseDownScreen.Y;
        if (!dragging && Math.Sqrt(dx * dx + dy * dy) >= DragThreshold)
        {
            dragging = true;
            DragStateChanged?.Invoke(this, true);
        }

        if (dragging)
        {
            Left = windowDown.X + dx;
            Top = windowDown.Y + dy;
        }
        e.Handled = true;
    }

    private void OnMouseUp(object sender, MouseButtonEventArgs e)
    {
        pointerDown = false;
        ReleaseMouseCapture();
        if (dragging)
            DragStateChanged?.Invoke(this, false);
        dragging = false;
        e.Handled = true;
    }
}
