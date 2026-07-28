using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using WpfImage = System.Windows.Controls.Image;
using WpfPanel = System.Windows.Controls.Panel;

namespace MonkeyDeskPets.Windows;

internal sealed class AboutWindow : Window
{
    private static string AppVersion =>
        typeof(AboutWindow).Assembly
            .GetCustomAttribute<AssemblyInformationalVersionAttribute>()?
            .InformationalVersion.Split('+')[0] ?? "0.3.0";
    private const string GitHub = "https://github.com/Im-Tim-mI";
    private const string Threads = "https://www.threads.com/@tim945_1";
    private const string Instagram = "https://www.instagram.com/tim945_1";
    private const string Shopee = "https://shopee.tw/rr901037";
    private const string Logitech = "https://store.logitech.tw/collections/logitech_gam";

    internal AboutWindow()
    {
        Title = L.T("關於 MonkeyDeskPets", "About MonkeyDeskPets");
        Width = 720;
        Height = 820;
        WindowStartupLocation = WindowStartupLocation.CenterScreen;
        ResizeMode = ResizeMode.NoResize;
        Topmost = true;

        var stack = new StackPanel { Margin = new Thickness(28) };
        var scroll = new ScrollViewer
        {
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Content = stack
        };
        Content = scroll;

        var avatar = LoadImage("author-avatar.png");
        avatar.Width = 130;
        avatar.Height = 130;
        avatar.Stretch = Stretch.UniformToFill;
        avatar.HorizontalAlignment = HorizontalAlignment.Center;
        stack.Children.Add(avatar);

        stack.Children.Add(new TextBlock
        {
            Text = L.T("MonkeyDeskPets 桌面猴群", "MonkeyDeskPets Desktop Pets"),
            FontSize = 23,
            FontWeight = FontWeights.Bold,
            TextAlignment = TextAlignment.Center,
            Margin = new Thickness(0, 10, 0, 5)
        });
        stack.Children.Add(new TextBlock
        {
            Text = L.T(
                $"版本：{AppVersion}\n作者：廷廷小教室、廷廷的家（Tim945）",
                $"Version: {AppVersion}\nAuthor: 廷廷小教室、廷廷的家（Tim945）"
            ),
            FontSize = 14,
            TextAlignment = TextAlignment.Center,
            Margin = new Thickness(0, 0, 0, 8)
        });

        AddLink(stack, "github:", GitHub);
        AddLink(stack, "threads:", Threads);
        AddLink(stack, "IG:", Instagram);
        AddLink(stack, L.T("作者官方商店（蝦皮）：", "Official Shopee Store:"), Shopee);

        stack.Children.Add(new TextBlock
        {
            Text = L.T(
                "MonkeyDeskPets Noncommercial License 1.0\n禁止商用，且必須保留作者資訊、官方連結與隨附推廣。",
                "MonkeyDeskPets Noncommercial License 1.0\nCommercial use is prohibited; attribution, official links, and bundled promotion must be retained."
            ),
            Foreground = Brushes.DimGray,
            FontWeight = FontWeights.SemiBold,
            TextAlignment = TextAlignment.Center,
            Margin = new Thickness(0, 10, 0, 10)
        });

        var ad = LoadImage("logitech-ad.jpeg");
        ad.Width = 560;
        ad.Height = 315;
        ad.Stretch = Stretch.Uniform;
        ad.Cursor = Cursors.Hand;
        ad.ToolTip = L.T("開啟羅技 Logi 網路旗艦店－電競專區", "Open Logitech Logi Gaming Store");
        ad.MouseLeftButtonUp += (_, _) => OpenUrl(Logitech);
        stack.Children.Add(ad);
        AddLink(
            stack,
            L.T("羅技Logi 網路旗艦店-電競專區：", "Logitech Logi Online Flagship Store - Gaming:"),
            Logitech
        );

        var terms = new Button
        {
            Content = L.T("查看完整「廣告與作者資訊保留條款」", "View Full Advertising and Attribution Terms"),
            Margin = new Thickness(0, 12, 0, 6),
            Padding = new Thickness(12, 6, 12, 6),
            HorizontalAlignment = HorizontalAlignment.Center
        };
        terms.Click += (_, _) => ShowTerms();
        stack.Children.Add(terms);
    }

    private static WpfImage LoadImage(string name)
    {
        var path = Path.Combine(AppContext.BaseDirectory, "Assets", name);
        var image = new BitmapImage();
        image.BeginInit();
        image.CacheOption = BitmapCacheOption.OnLoad;
        image.UriSource = new Uri(path);
        image.EndInit();
        image.Freeze();
        return new WpfImage { Source = image };
    }

    private static void AddLink(WpfPanel panel, string label, string url)
    {
        var row = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            HorizontalAlignment = HorizontalAlignment.Left,
            Margin = new Thickness(35, 2, 0, 2)
        };
        row.Children.Add(new TextBlock { Text = label + " ", Foreground = Brushes.Black });
        var link = new TextBlock
        {
            Text = url,
            Foreground = Brushes.RoyalBlue,
            TextDecorations = TextDecorations.Underline,
            Cursor = Cursors.Hand
        };
        link.MouseLeftButtonUp += (_, _) => OpenUrl(url);
        row.Children.Add(link);
        panel.Children.Add(row);
    }

    private static void OpenUrl(string url) =>
        Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });

    private void ShowTerms()
    {
        var languageFile = L.IsChinese
            ? "ADDITIONAL-TERMS-zh-TW.txt"
            : "ADDITIONAL-TERMS-en.txt";
        var path = Path.Combine(AppContext.BaseDirectory, "Licenses", languageFile);
        var text = File.Exists(path)
            ? File.ReadAllText(path)
            : L.T("找不到授權條款檔案。", "The license terms file could not be found.");
        var dialog = new Window
        {
            Owner = this,
            Title = L.T("廣告與作者資訊保留條款", "Advertising and Author Information Retention Terms"),
            Width = 720,
            Height = 650,
            Content = new TextBox
            {
                Text = text,
                IsReadOnly = true,
                TextWrapping = TextWrapping.Wrap,
                VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
                Margin = new Thickness(16)
            }
        };
        dialog.ShowDialog();
    }
}
