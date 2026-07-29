using Microsoft.Win32;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Threading;
using DrawingIcon = System.Drawing.Icon;
using DrawingSystemIcons = System.Drawing.SystemIcons;
using Forms = System.Windows.Forms;
using WpfPoint = System.Windows.Point;
using WpfVector = System.Windows.Vector;

namespace MonkeyDeskPets.Windows;

/// <summary>
/// Windows 平台控制器。
/// 行為週期、重力、碰撞、餵食、喊爸與動畫狀態均以 macOS 版為基準，
/// 僅將視窗、通知區及座標方向改寫為 WPF／Windows 實作。
/// </summary>
internal sealed class DesktopPetController : IDisposable
{
    private const double PetWidth = 156;
    private const double PetHeight = 187;
    private const double TickInterval = 1.0 / 60.0;
    private const double Gravity = 28;
    private const double DadFallSpeed = 720;
    private const double DadSpeechDuration = 2.0;
    private const double EatingDuration = 2.4;
    private const double FoodApproachSpeed = 165;

    private sealed class Food
    {
        internal FoodWindow Window { get; }
        internal WpfPoint Center => Window.Center;
        internal PetWindow? ClaimedBy { get; set; }

        internal Food(WpfPoint point)
        {
            Window = new FoodWindow(point);
        }
    }

    private readonly SpriteStore sprites = new();
    private readonly List<PetWindow> pets = [];
    private readonly List<Food> foods = [];
    private readonly Dictionary<PetWindow, Food> foodTargets = [];
    private readonly Random random = new();
    private readonly DispatcherTimer timer;
    private readonly Forms.NotifyIcon trayIcon;
    private IReadOnlyList<Rect> obstacles = [];
    private PlacementWindow? placementWindow;
    private double obstacleClock;
    private double dadSpeakingTimeRemaining;
    private bool paused;
    private bool ignoreMouse = true;
    private bool isDadLanding;
    private bool disposed;

    internal DesktopPetController()
    {
        timer = new DispatcherTimer
        {
            Interval = TimeSpan.FromSeconds(TickInterval)
        };
        timer.Tick += (_, _) => Tick(TickInterval);

        var iconPath = Path.Combine(AppContext.BaseDirectory, "Assets", "MonkeyDeskPets.ico");
        trayIcon = new Forms.NotifyIcon
        {
            Text = "MonkeyDeskPets",
            Icon = File.Exists(iconPath) ? new DrawingIcon(iconPath) : DrawingSystemIcons.Application,
            Visible = true
        };
        trayIcon.DoubleClick += (_, _) => ShowAbout();
        RebuildMenu();
    }

    internal void Start()
    {
        try
        {
            sprites.Load();
            AddPet();
            timer.Start();
        }
        catch (Exception exception)
        {
            MessageBox.Show(
                exception.Message,
                L.T("MonkeyDeskPets 無法啟動", "MonkeyDeskPets could not start"),
                MessageBoxButton.OK,
                MessageBoxImage.Error
            );
            System.Windows.Application.Current.Shutdown(1);
        }
    }

    private static string AppVersion =>
        typeof(DesktopPetController).Assembly
            .GetCustomAttribute<AssemblyInformationalVersionAttribute>()?
            .InformationalVersion.Split('+')[0] ?? "0.3.3";

    private void RebuildMenu()
    {
        var oldMenu = trayIcon.ContextMenuStrip;
        var menu = new Forms.ContextMenuStrip();

        menu.Items.Add(DisabledItem(L.T($"角色：{pets.Count}", $"Characters: {pets.Count}")));
        menu.Items.Add(DisabledItem(L.T($"版本：{AppVersion}", $"Version: {AppVersion}")));
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.Add(Item(L.T("增加一人", "Add Character"), (_, _) => AddPet()));
        menu.Items.Add(Item(L.T("減少一人", "Remove Character"), (_, _) => RemoveOne()));
        menu.Items.Add(Item(L.T("只保留一人", "Keep Only One"), (_, _) => KeepOne()));
        menu.Items.Add(Item(L.T("餵食", "Feed"), (_, _) => BeginFeedPlacement()));
        menu.Items.Add(Item(L.T("爸", "Dad"), (_, _) => BeginDadSequence()));
        menu.Items.Add(Item(L.T("上傳精靈圖", "Upload Sprite Sheet"), (_, _) => UploadSprites()));
        menu.Items.Add(Item(
            L.T("懶人模式（上傳臉部）", "Easy Mode (Upload Face)"),
            (_, _) => UploadFaceForEasyMode()
        ));
        menu.Items.Add(Item(
            L.T("恢復預設精靈圖", "Restore Default Sprites"),
            (_, _) => ResetSprites()
        ));
        menu.Items.Add(Item(
            L.T("開啟精靈圖目錄", "Open Sprite Folder"),
            (_, _) => OpenSpriteDirectory()
        ));
        menu.Items.Add(Item(
            paused ? L.T("繼續玩耍", "Resume") : L.T("暫停", "Pause"),
            (_, _) =>
            {
                paused = !paused;
                RebuildMenu();
            }
        ));
        menu.Items.Add(Item(
            ignoreMouse
                ? L.T("允許拖曳人物", "Enable Character Dragging")
                : L.T("忽略滑鼠（推薦）", "Ignore Mouse (Recommended)"),
            (_, _) =>
            {
                ignoreMouse = !ignoreMouse;
                foreach (var pet in pets)
                    pet.IsHitTestVisible = !ignoreMouse;
                RebuildMenu();
            }
        ));
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.Add(Item(
            L.T("關於 MonkeyDeskPets", "About MonkeyDeskPets"),
            (_, _) => ShowAbout()
        ));
        menu.Items.Add(Item(
            L.T("結束桌面猴群", "Quit MonkeyDeskPets"),
            (_, _) => System.Windows.Application.Current.Shutdown()
        ));

        trayIcon.ContextMenuStrip = menu;
        oldMenu?.Dispose();
    }

    private static Forms.ToolStripMenuItem DisabledItem(string text) =>
        new(text) { Enabled = false };

    private static Forms.ToolStripMenuItem Item(string text, EventHandler click)
    {
        var item = new Forms.ToolStripMenuItem(text);
        item.Click += click;
        return item;
    }

    private void AddPet()
    {
        if (sprites.Frames.Count == 0)
            return;

        var left = SystemParameters.VirtualScreenLeft;
        var top = SystemParameters.VirtualScreenTop;
        var width = Math.Max(1, SystemParameters.VirtualScreenWidth - PetWidth);
        var height = Math.Max(1, SystemParameters.VirtualScreenHeight - PetHeight);
        var direction = random.Next(0, 2) == 0 ? -1d : 1d;
        var age = RandomBetween(0, 20);
        var pet = new PetWindow
        {
            Left = left + random.NextDouble() * width,
            Top = top + random.NextDouble() * height,
            VelocityX = direction * RandomBetween(75, 135),
            VelocityY = RandomBetween(-25, 15),
            Age = age,
            NextVerticalActionAge = age + RandomBetween(2.5, 5.5),
            CurrentPose = Pose.CrawlA,
            IsHitTestVisible = !ignoreMouse
        };
        pet.DragStateChanged = OnDragChanged;
        SetPose(pet, Pose.CrawlA);
        pets.Add(pet);
        pet.Show();
        AssignAvailableFood();
        RebuildMenu();
    }

    private void RemoveOne()
    {
        if (pets.Count == 0)
            return;
        RemovePet(pets[^1]);
        RebuildMenu();
    }

    private void KeepOne()
    {
        if (pets.Count <= 1)
            return;
        foreach (var pet in pets.Skip(1).ToArray())
            RemovePet(pet);
        RebuildMenu();
    }

    private void RemovePet(PetWindow pet)
    {
        if (foodTargets.Remove(pet, out var targetFood))
            targetFood.ClaimedBy = null;

        var center = new WpfPoint(pet.Left + PetWidth / 2, pet.Top + PetHeight / 2);
        pets.Remove(pet);
        pet.Close();
        new ExplosionWindow(center).Show();
        AssignAvailableFood();
    }

    private void OnDragChanged(PetWindow pet, bool isDragging)
    {
        pet.IsBusy = isDragging;
        pet.VelocityX = 0;
        pet.VelocityY = 0;
        pet.PoseClock = 0;
        pet.ShowSpeech(false);

        if (isDragging)
        {
            SetPose(pet, Pose.Hang);
        }
        else
        {
            SetPose(pet, Pose.Crouch);
            ClampPet(pet);
        }
    }

    private void Tick(double delta)
    {
        RecoverPetWindows();

        if (isDadLanding)
        {
            UpdateDadLanding(delta);
            return;
        }

        if (dadSpeakingTimeRemaining > 0)
        {
            dadSpeakingTimeRemaining = Math.Max(0, dadSpeakingTimeRemaining - delta);
            foreach (var pet in pets)
            {
                if (pet.IsBusy)
                {
                    pet.VelocityX = 0;
                    pet.VelocityY = 0;
                    SetPose(pet, Pose.Hang);
                    continue;
                }
                pet.VelocityX = 0;
                pet.VelocityY = 0;
                SetPose(pet, Pose.Crouch);
                if (dadSpeakingTimeRemaining == 0)
                    pet.ShowSpeech(false);
            }
            return;
        }

        if (paused)
            return;

        obstacleClock += delta;
        if (obstacleClock >= 0.35)
        {
            obstacleClock = 0;
            obstacles = WindowObstacles.ReadVisibleWindows();
        }

        foreach (var pet in pets)
        {
            if (pet.IsBusy)
            {
                pet.ActivateTopmost();
                continue;
            }
            if (UpdateFeeding(pet, delta))
            {
                ClampPet(pet);
                continue;
            }

            pet.Age += delta;
            pet.PoseClock += delta;
            UpdateBehavior(pet, delta);
            ResolveScreenEdges(pet);
            ResolveWindowCollisions(pet);
            ClampPet(pet);
            UpdatePose(pet);
        }
    }

    private void RecoverPetWindows()
    {
        foreach (var pet in pets)
        {
            if (pet.Opacity != 1)
                pet.Opacity = 1;
            if (!pet.HasFrame && sprites.Frames.Count > 0)
                SetPose(pet, Pose.CrawlA);
            if (!pet.IsBusy)
                ClampPet(pet);
            pet.ActivateTopmost();
        }
    }

    private void UpdateBehavior(PetWindow pet, double delta)
    {
        var wasSupported = pet.IsSupported;
        pet.IsSupported = false;
        pet.VelocityY += Gravity * delta;

        // Vertical movement has its own randomized schedule. A pet that is
        // standing on the desktop or a window edge will periodically launch
        // into a substantial diagonal jump instead of remaining on one row.
        if (pet.Age >= pet.NextVerticalActionAge &&
            (wasSupported || Math.Abs(pet.VelocityY) < 45))
        {
            var keepDirection = Math.Abs(pet.VelocityX) >= 1 && random.NextDouble() < 0.55;
            var direction = keepDirection
                ? Math.Sign(pet.VelocityX)
                : (random.Next(0, 2) == 0 ? -1 : 1);
            pet.VelocityX = direction * RandomBetween(70, 145);
            pet.VelocityY = -RandomBetween(120, 220);
            pet.NextVerticalActionAge = pet.Age + RandomBetween(3.8, 7.2);
            pet.CurrentPose = Pose.Leap;
            pet.PoseClock = 0;
        }

        if ((int)pet.Age % 17 >= 14)
        {
            pet.VelocityX *= 0.975;
            pet.CurrentPose = (int)pet.Age % 17 == 16 ? Pose.Sleep : Pose.Sit;
        }
        else
        {
            if (pet.CurrentPose is Pose.Sit or Pose.Sleep)
            {
                pet.CurrentPose = Pose.CrawlA;
                pet.PoseClock = 0;
            }
            if (Math.Abs(pet.VelocityX) < 45)
                pet.VelocityX = (random.Next(0, 2) == 0 ? -1 : 1) * RandomBetween(70, 120);
        }

        pet.Left += pet.VelocityX * delta;
        pet.Top += pet.VelocityY * delta;
        pet.FacingRight = pet.VelocityX >= 0;
    }

    private void ResolveScreenEdges(PetWindow pet)
    {
        var left = SystemParameters.VirtualScreenLeft;
        var top = SystemParameters.VirtualScreenTop;
        var right = left + SystemParameters.VirtualScreenWidth - PetWidth;
        var bottom = top + SystemParameters.VirtualScreenHeight - PetHeight;

        if (pet.Left <= left)
        {
            pet.Left = left;
            pet.VelocityX = Math.Abs(pet.VelocityX);
            pet.VelocityY = -RandomBetween(85, 155);
            pet.NextVerticalActionAge = pet.Age + RandomBetween(3.8, 7.2);
            pet.CurrentPose = Pose.Climb;
            pet.PoseClock = 0;
        }
        else if (pet.Left >= right)
        {
            pet.Left = right;
            pet.VelocityX = -Math.Abs(pet.VelocityX);
            pet.VelocityY = -RandomBetween(85, 155);
            pet.NextVerticalActionAge = pet.Age + RandomBetween(3.8, 7.2);
            pet.CurrentPose = Pose.Climb;
            pet.PoseClock = 0;
        }

        if (pet.Top <= top)
        {
            pet.Top = top;
            pet.VelocityY = Math.Abs(pet.VelocityY) * 0.55;
            pet.CurrentPose = Pose.Hang;
            pet.PoseClock = 0;
        }
        else if (pet.Top >= bottom)
        {
            pet.Top = bottom;
            pet.VelocityY = 0;
            pet.IsSupported = true;
        }
    }

    private void ResolveWindowCollisions(PetWindow pet)
    {
        if (pet.VelocityY < 0)
            return;

        var feetLeft = pet.Left + 28;
        var feetRight = pet.Left + PetWidth - 28;
        var feetTop = pet.Top + PetHeight - 25;
        var feetBottom = pet.Top + PetHeight;

        foreach (var obstacle in obstacles)
        {
            var intersects =
                feetRight > obstacle.Left &&
                feetLeft < obstacle.Right &&
                feetBottom > obstacle.Top &&
                feetTop < obstacle.Bottom;
            if (!intersects)
                continue;

            var overlap = feetBottom - obstacle.Top;
            if (overlap <= 0 || overlap >= 40)
                continue;

            pet.Top = obstacle.Top - PetHeight;
            pet.VelocityY = 0;
            pet.IsSupported = true;
            pet.CurrentPose = Pose.Crouch;
            pet.PoseClock = 0;
            return;
        }
    }

    private void UpdatePose(PetWindow pet)
    {
        var next = pet.CurrentPose;
        switch (pet.CurrentPose)
        {
            case Pose.CrawlA:
            case Pose.CrawlB:
                next = (int)(pet.Age * 7) % 2 == 0 ? Pose.CrawlA : Pose.CrawlB;
                break;
            case Pose.Sit:
            case Pose.Sleep:
                break;
            case Pose.Climb:
            case Pose.Hang:
            case Pose.Crouch:
            case Pose.Leap:
                if (pet.PoseClock > 0.65)
                {
                    pet.CurrentPose = Pose.CrawlA;
                    pet.PoseClock = 0;
                    next = Pose.CrawlA;
                }
                break;
        }
        SetPose(pet, next);
    }

    private bool UpdateFeeding(PetWindow pet, double delta)
    {
        if (!foodTargets.TryGetValue(pet, out var food))
            return false;

        if (pet.EatingTimeRemaining > 0)
        {
            var elapsed = EatingDuration - pet.EatingTimeRemaining;
            pet.EatingTimeRemaining = Math.Max(0, pet.EatingTimeRemaining - delta);
            pet.VelocityX = 0;
            pet.VelocityY = 0;
            SetPose(pet, Pose.CrawlB);
            pet.FacingRight = pet.EatingDirection.X >= 0;

            if (pet.EatingAnchor is WpfPoint anchor)
            {
                var offset = Math.Sin(elapsed * Math.PI * 4) * 7;
                pet.Left = anchor.X + pet.EatingDirection.X * offset;
                pet.Top = anchor.Y + pet.EatingDirection.Y * offset;
            }

            if (pet.EatingTimeRemaining == 0)
            {
                if (pet.EatingAnchor is WpfPoint finalAnchor)
                {
                    pet.Left = finalAnchor.X;
                    pet.Top = finalAnchor.Y;
                }
                food.Window.Close();
                foods.Remove(food);
                foodTargets.Remove(pet);
                pet.EatingAnchor = null;
                pet.PoseClock = 0;
                AssignAvailableFood();
            }
            return true;
        }

        var petCenter = new WpfPoint(pet.Left + PetWidth / 2, pet.Top + PetHeight / 2);
        var deltaX = food.Center.X - petCenter.X;
        var deltaY = food.Center.Y - petCenter.Y;
        var distance = Math.Sqrt(deltaX * deltaX + deltaY * deltaY);

        if (distance <= 86)
        {
            pet.EatingTimeRemaining = EatingDuration;
            pet.EatingAnchor = new WpfPoint(pet.Left, pet.Top);
            pet.EatingDirection = distance > 0
                ? new WpfVector(deltaX / distance, deltaY / distance)
                : new WpfVector(pet.VelocityX < 0 ? -1 : 1, 0);
            pet.VelocityX = 0;
            pet.VelocityY = 0;
            SetPose(pet, Pose.CrawlB);
            return true;
        }

        var step = Math.Min(FoodApproachSpeed * delta, distance);
        var movementX = deltaX / distance * step;
        var movementY = deltaY / distance * step;
        pet.Left += movementX;
        pet.Top += movementY;
        pet.VelocityX = movementX / delta;
        pet.VelocityY = movementY / delta;
        pet.FacingRight = pet.VelocityX >= 0;
        pet.Age += delta;
        SetPose(pet, (int)(pet.Age * 7) % 2 == 0 ? Pose.CrawlA : Pose.CrawlB);
        return true;
    }

    private void BeginFeedPlacement()
    {
        placementWindow?.Close();
        placementWindow = new PlacementWindow();
        placementWindow.PositionChosen += PlaceFood;
        placementWindow.Closed += (_, _) => placementWindow = null;
        placementWindow.Show();
        placementWindow.Activate();
        placementWindow.Focus();
    }

    private void PlaceFood(WpfPoint point)
    {
        placementWindow?.Close();
        var food = new Food(point);
        foods.Add(food);
        food.Window.Show();
        AssignAvailableFood();
    }

    private void AssignAvailableFood()
    {
        foreach (var food in foods.Where(candidate => candidate.ClaimedBy is null))
        {
            var nearestPet = pets
                .Where(pet => !foodTargets.ContainsKey(pet))
                .OrderBy(pet => DistanceSquared(
                    new WpfPoint(pet.Left + PetWidth / 2, pet.Top + PetHeight / 2),
                    food.Center
                ))
                .FirstOrDefault();
            if (nearestPet is null)
                continue;

            food.ClaimedBy = nearestPet;
            foodTargets[nearestPet] = food;
            nearestPet.EatingTimeRemaining = 0;
            nearestPet.EatingAnchor = null;
        }
    }

    private void BeginDadSequence()
    {
        if (pets.Count == 0)
            return;

        isDadLanding = true;
        dadSpeakingTimeRemaining = 0;
        foreach (var pet in pets)
        {
            pet.ShowSpeech(false);
            pet.PoseClock = 0;
            pet.VelocityX = 0;
            pet.VelocityY = DadFallSpeed;
            if (pet.IsBusy)
            {
                SetPose(pet, Pose.Hang);
                continue;
            }
            SetPose(pet, Pose.Crouch);
        }
    }

    private void UpdateDadLanding(double delta)
    {
        var allReachedBottom = true;
        var bottom = SystemParameters.VirtualScreenTop +
                     SystemParameters.VirtualScreenHeight -
                     PetHeight;

        foreach (var pet in pets)
        {
            if (pet.IsBusy)
            {
                allReachedBottom = false;
                continue;
            }
            if (pet.Top < bottom)
            {
                allReachedBottom = false;
                pet.Top = Math.Min(bottom, pet.Top + DadFallSpeed * delta);
            }
            pet.VelocityX = 0;
            pet.VelocityY = 0;
            SetPose(pet, Pose.Crouch);
            ClampPet(pet);
        }

        if (!allReachedBottom)
            return;

        isDadLanding = false;
        dadSpeakingTimeRemaining = DadSpeechDuration;
        foreach (var pet in pets)
        {
            pet.PoseClock = 0;
            SetPose(pet, Pose.Crouch);
            pet.ShowSpeech(true);
        }
    }

    private void UploadSprites()
    {
        var dialog = new OpenFileDialog
        {
            Title = L.T("選擇 4×2 精靈圖", "Choose a 4×2 Sprite Sheet"),
            Filter = L.T(
                "圖片檔案|*.png;*.jpg;*.jpeg;*.bmp",
                "Image files|*.png;*.jpg;*.jpeg;*.bmp"
            )
        };
        if (dialog.ShowDialog() != true)
            return;
        if (!sprites.Import(dialog.FileName, out var error))
        {
            MessageBox.Show(error, "MonkeyDeskPets", MessageBoxButton.OK, MessageBoxImage.Warning);
            return;
        }
        RefreshFrames();
    }

    private void ResetSprites()
    {
        var result = MessageBox.Show(
            L.T("確定要恢復程式內建精靈圖嗎？", "Restore the bundled default sprites?"),
            "MonkeyDeskPets",
            MessageBoxButton.YesNo,
            MessageBoxImage.Question
        );
        if (result != MessageBoxResult.Yes)
            return;
        sprites.Reset();
        RefreshFrames();
    }

    private void UploadFaceForEasyMode()
    {
        var dialog = new OpenFileDialog
        {
            Title = L.T(
                "懶人模式：選擇清楚的臉部照片",
                "Easy Mode: Choose a Clear Face Photo"
            ),
            Filter = L.T(
                "圖片檔案|*.png;*.jpg;*.jpeg;*.bmp",
                "Image files|*.png;*.jpg;*.jpeg;*.bmp"
            )
        };
        if (dialog.ShowDialog() != true)
            return;

        if (!FaceComposer.TryGenerate(
                dialog.FileName,
                sprites.BundledPath,
                out var generated,
                out var error
            ) ||
            !sprites.ImportGenerated(generated, dialog.FileName, out error))
        {
            MessageBox.Show(
                error,
                L.T("懶人模式失敗", "Easy Mode Failed"),
                MessageBoxButton.OK,
                MessageBoxImage.Warning
            );
            return;
        }

        RefreshFrames();
        MessageBox.Show(
            L.T(
                "已在本機生成 4×2 精靈圖並立即套用。臉部照片不會上傳網路。",
                "A 4×2 sprite sheet was generated locally and applied. The face photo was not uploaded."
            ),
            L.T("懶人模式已完成", "Easy Mode Complete"),
            MessageBoxButton.OK,
            MessageBoxImage.Information
        );
    }

    private void RefreshFrames()
    {
        foreach (var pet in pets)
            SetPose(pet, Pose.Crouch);
    }

    private void OpenSpriteDirectory()
    {
        Directory.CreateDirectory(sprites.SpriteDirectory);
        Process.Start(new ProcessStartInfo("explorer.exe", sprites.SpriteDirectory)
        {
            UseShellExecute = true
        });
    }

    private static void ShowAbout()
    {
        var about = new AboutWindow();
        about.Show();
        about.Activate();
    }

    private void SetPose(PetWindow pet, Pose pose)
    {
        if (sprites.Frames.Count <= (int)pose)
            return;
        pet.CurrentPose = pose;
        pet.SetFrame(sprites.Frames[(int)pose], pet.FacingRight);
    }

    private static double DistanceSquared(WpfPoint first, WpfPoint second)
    {
        var dx = first.X - second.X;
        var dy = first.Y - second.Y;
        return dx * dx + dy * dy;
    }

    private double RandomBetween(double minimum, double maximum) =>
        minimum + random.NextDouble() * (maximum - minimum);

    private static double Clamp(double value, double minimum, double maximum) =>
        Math.Min(maximum, Math.Max(minimum, value));

    private static void ClampPet(PetWindow pet)
    {
        var left = SystemParameters.VirtualScreenLeft;
        var top = SystemParameters.VirtualScreenTop;
        var right = left + SystemParameters.VirtualScreenWidth - PetWidth;
        var bottom = top + SystemParameters.VirtualScreenHeight - PetHeight;
        pet.Left = Clamp(double.IsFinite(pet.Left) ? pet.Left : left, left, right);
        pet.Top = Clamp(double.IsFinite(pet.Top) ? pet.Top : bottom, top, bottom);
        if (!pet.IsVisible)
            pet.Show();
        pet.Opacity = 1;
    }

    public void Dispose()
    {
        if (disposed)
            return;
        disposed = true;
        timer.Stop();
        placementWindow?.Close();
        foreach (var food in foods)
            food.Window.Close();
        foods.Clear();
        foodTargets.Clear();
        foreach (var pet in pets.ToArray())
            pet.Close();
        pets.Clear();
        trayIcon.Visible = false;
        trayIcon.ContextMenuStrip?.Dispose();
        trayIcon.Dispose();
    }
}
