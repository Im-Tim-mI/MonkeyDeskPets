using Microsoft.Win32;
using System.Diagnostics;
using System.IO;
using System.Windows;
using System.Windows.Threading;
using DrawingIcon = System.Drawing.Icon;
using DrawingSystemIcons = System.Drawing.SystemIcons;
using Forms = System.Windows.Forms;

namespace MonkeyDeskPets.Windows;

internal sealed class DesktopPetController : IDisposable
{
    private const double PetWidth = 156;
    private const double PetHeight = 167;
    private readonly SpriteStore sprites = new();
    private readonly List<PetWindow> pets = [];
    private readonly Random random = new();
    private readonly DispatcherTimer movementTimer;
    private readonly DispatcherTimer behaviorTimer;
    private readonly Forms.NotifyIcon trayIcon;
    private FoodWindow? food;
    private PetWindow? eater;
    private DateTime eatingUntil;
    private DateTime dadSpeechUntil;
    private bool paused;
    private bool ignoreMouse;
    private bool dadSequence;
    private int animationTick;
    private IReadOnlyList<Rect> obstacles = [];

    internal DesktopPetController()
    {
        movementTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(33) };
        movementTimer.Tick += (_, _) => Update();
        behaviorTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(2.2) };
        behaviorTimer.Tick += (_, _) => ChooseBehaviors();

        var iconPath = Path.Combine(AppContext.BaseDirectory, "Assets", "MonkeyDeskPets.ico");
        trayIcon = new Forms.NotifyIcon
        {
            Text = "MonkeyDeskPets",
            Icon = File.Exists(iconPath) ? new DrawingIcon(iconPath) : DrawingSystemIcons.Application,
            Visible = true
        };
        trayIcon.ContextMenuStrip = BuildMenu();
        trayIcon.DoubleClick += (_, _) => ShowAbout();
    }

    internal void Start()
    {
        try
        {
            sprites.Load();
            AddPet();
            movementTimer.Start();
            behaviorTimer.Start();
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

    private Forms.ContextMenuStrip BuildMenu()
    {
        var menu = new Forms.ContextMenuStrip();
        menu.Items.Add(Item(L.T("增加一人", "Add Pet"), (_, _) => AddPet()));
        menu.Items.Add(Item(L.T("減少一人", "Remove Pet"), (_, _) => RemoveOne()));
        menu.Items.Add(Item(L.T("只保留一人", "Keep One Pet"), (_, _) => KeepOne()));
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.Add(Item(L.T("餵食", "Feed"), (_, _) => BeginFeedPlacement()));
        menu.Items.Add(Item(L.T("爸", "Dad"), (_, _) => BeginDadSequence()));
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.Add(Item(L.T("上傳精靈圖", "Upload Sprite Sheet"), (_, _) => UploadSprites()));
        menu.Items.Add(Item(
            L.T("懶人模式（上傳臉部）", "Easy Mode (Upload Face)"),
            (_, _) => UploadFaceForEasyMode()
        ));
        menu.Items.Add(Item(L.T("恢復預設精靈圖", "Restore Default Sprites"), (_, _) => ResetSprites()));
        menu.Items.Add(Item(L.T("開啟精靈圖目錄", "Open Sprite Folder"), (_, _) => OpenSpriteDirectory()));
        menu.Items.Add(new Forms.ToolStripSeparator());

        var pause = Item(L.T("暫停玩耍", "Pause"), null);
        pause.Click += (_, _) =>
        {
            paused = !paused;
            pause.Text = paused ? L.T("繼續玩耍", "Resume") : L.T("暫停玩耍", "Pause");
        };
        menu.Items.Add(pause);

        var mouse = Item(L.T("忽略滑鼠", "Ignore Mouse"), null);
        mouse.Click += (_, _) =>
        {
            ignoreMouse = !ignoreMouse;
            foreach (var pet in pets)
                pet.IsHitTestVisible = !ignoreMouse;
            mouse.Text = ignoreMouse ? L.T("允許拖曳", "Enable Dragging") : L.T("忽略滑鼠", "Ignore Mouse");
        };
        menu.Items.Add(mouse);

        menu.Items.Add(Item(L.T("關於 MonkeyDeskPets", "About MonkeyDeskPets"), (_, _) => ShowAbout()));
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.Add(Item(L.T("結束", "Quit"), (_, _) => System.Windows.Application.Current.Shutdown()));
        return menu;
    }

    private static Forms.ToolStripMenuItem Item(string text, EventHandler? click)
    {
        var item = new Forms.ToolStripMenuItem(text);
        if (click is not null)
            item.Click += click;
        return item;
    }

    private void AddPet()
    {
        var pet = new PetWindow
        {
            Left = Clamp(
                SystemParameters.VirtualScreenLeft + 40 + random.NextDouble() *
                Math.Max(1, SystemParameters.VirtualScreenWidth - PetWidth - 80),
                SystemParameters.VirtualScreenLeft,
                SystemParameters.VirtualScreenLeft + SystemParameters.VirtualScreenWidth - PetWidth
            ),
            Top = SystemParameters.VirtualScreenTop + SystemParameters.VirtualScreenHeight - PetHeight,
            VelocityX = random.Next(0, 2) == 0 ? -95 : 95,
            IsHitTestVisible = !ignoreMouse
        };
        pet.DragStateChanged = OnDragChanged;
        pet.SetFrame(sprites.Frames[(int)Pose.Crouch], true);
        pets.Add(pet);
        pet.Show();
    }

    private void RemoveOne()
    {
        if (pets.Count <= 1)
            return;
        RemovePet(pets[^1]);
    }

    private void KeepOne()
    {
        foreach (var pet in pets.Skip(1).ToArray())
            RemovePet(pet);
    }

    private void RemovePet(PetWindow pet)
    {
        var explosion = new ExplosionWindow(new Point(pet.Left + PetWidth / 2, pet.Top + PetHeight / 2));
        explosion.Show();
        pets.Remove(pet);
        if (ReferenceEquals(eater, pet))
            ClearFood();
        pet.Close();
    }

    private void OnDragChanged(PetWindow pet, bool isDragging)
    {
        pet.IsBusy = isDragging;
        pet.VelocityX = 0;
        pet.VelocityY = 0;
        if (isDragging)
        {
            pet.FoodTarget = null;
            pet.ShowSpeech(false);
            pet.SetFrame(sprites.Frames[(int)Pose.Hang], pet.FacingRight);
        }
        else
        {
            pet.VelocityY = 40;
            ClampPet(pet);
        }
    }

    private void ChooseBehaviors()
    {
        if (paused || dadSequence)
            return;

        foreach (var pet in pets.Where(candidate => !candidate.IsBusy && candidate.FoodTarget is null))
        {
            var choice = random.Next(0, 6);
            if (choice == 0)
            {
                pet.VelocityX = 0;
                pet.SetFrame(sprites.Frames[(int)Pose.Sit], pet.FacingRight);
            }
            else if (choice == 1)
            {
                pet.VelocityX = 0;
                pet.SetFrame(sprites.Frames[(int)Pose.Sleep], pet.FacingRight);
            }
            else
            {
                pet.VelocityX = (random.Next(0, 2) == 0 ? -1 : 1) * (70 + random.NextDouble() * 75);
                pet.FacingRight = pet.VelocityX >= 0;
            }
        }
    }

    private void Update()
    {
        animationTick++;
        if (animationTick % 15 == 1)
            obstacles = WindowObstacles.ReadVisibleWindows();
        var delta = movementTimer.Interval.TotalSeconds;
        var left = SystemParameters.VirtualScreenLeft;
        var top = SystemParameters.VirtualScreenTop;
        var right = left + SystemParameters.VirtualScreenWidth - PetWidth;
        var bottom = top + SystemParameters.VirtualScreenHeight - PetHeight;

        foreach (var pet in pets)
        {
            if (pet.IsBusy)
            {
                ClampPet(pet);
                continue;
            }

            if (dadSequence)
            {
                pet.SetFrame(sprites.Frames[(int)Pose.Crouch], pet.FacingRight);
                if (pet.Top < bottom)
                    pet.Top = Math.Min(bottom, pet.Top + 680 * delta);
                continue;
            }

            if (ReferenceEquals(pet, eater) && pet.FoodTarget is Point target)
            {
                UpdateEater(pet, target, delta);
                continue;
            }

            if (paused)
                continue;

            var previousBottom = pet.Top + PetHeight;
            pet.Left += pet.VelocityX * delta;
            pet.Top += pet.VelocityY * delta;
            pet.VelocityY += 270 * delta;

            if (pet.Left <= left || pet.Left >= right)
            {
                pet.Left = Clamp(pet.Left, left, right);
                pet.VelocityX = -pet.VelocityX;
                pet.FacingRight = pet.VelocityX >= 0;
                pet.SetFrame(sprites.Frames[(int)Pose.Climb], pet.FacingRight);
            }

            var obstacleTop = FindLandingSurface(pet, previousBottom);
            if (obstacleTop is double surface)
            {
                pet.Top = surface - PetHeight;
                pet.VelocityY = 0;
                if (Math.Abs(pet.VelocityX) > 1)
                {
                    var pose = animationTick / 8 % 2 == 0 ? Pose.CrawlA : Pose.CrawlB;
                    pet.SetFrame(sprites.Frames[(int)pose], pet.FacingRight);
                }
            }
            else if (pet.Top >= bottom)
            {
                pet.Top = bottom;
                pet.VelocityY = 0;
                if (Math.Abs(pet.VelocityX) > 1)
                {
                    var pose = animationTick / 8 % 2 == 0 ? Pose.CrawlA : Pose.CrawlB;
                    pet.SetFrame(sprites.Frames[(int)pose], pet.FacingRight);
                }
            }
            else
            {
                pet.SetFrame(sprites.Frames[(int)Pose.Leap], pet.FacingRight);
            }
            ClampPet(pet);
        }

        if (dadSequence && pets.All(pet => Math.Abs(pet.Top - bottom) < 0.5))
        {
            if (dadSpeechUntil == default)
            {
                dadSpeechUntil = DateTime.UtcNow.AddSeconds(2.2);
                foreach (var pet in pets)
                    pet.ShowSpeech(true);
            }
            else if (DateTime.UtcNow >= dadSpeechUntil)
            {
                foreach (var pet in pets)
                {
                    pet.ShowSpeech(false);
                    pet.VelocityX = random.Next(0, 2) == 0 ? -90 : 90;
                }
                dadSequence = false;
                dadSpeechUntil = default;
            }
        }
    }

    private void UpdateEater(PetWindow pet, Point target, double delta)
    {
        var petCenter = new Point(pet.Left + PetWidth / 2, pet.Top + PetHeight / 2);
        var dx = target.X - petCenter.X;
        var dy = target.Y - petCenter.Y;
        var distance = Math.Sqrt(dx * dx + dy * dy);
        pet.FacingRight = dx >= 0;

        if (distance > 42 && eatingUntil == default)
        {
            var speed = 190d;
            pet.Left += dx / distance * speed * delta;
            pet.Top += dy / distance * speed * delta;
            var pose = animationTick / 7 % 2 == 0 ? Pose.CrawlA : Pose.CrawlB;
            pet.SetFrame(sprites.Frames[(int)pose], pet.FacingRight);
        }
        else
        {
            if (eatingUntil == default)
                eatingUntil = DateTime.UtcNow.AddSeconds(2.4);
            var offset = animationTick / 5 % 2 == 0 ? 4 : -4;
            pet.Left += offset;
            pet.SetFrame(sprites.Frames[(int)Pose.CrawlB], pet.FacingRight);
            if (DateTime.UtcNow >= eatingUntil)
            {
                pet.FoodTarget = null;
                pet.VelocityX = pet.FacingRight ? 90 : -90;
                ClearFood();
            }
        }
        ClampPet(pet);
    }

    private void BeginFeedPlacement()
    {
        if (pets.Count == 0 || dadSequence)
            return;
        var placement = new PlacementWindow();
        placement.PositionChosen += PlaceFood;
        placement.Show();
        placement.Activate();
        placement.Focus();
    }

    private void PlaceFood(Point position)
    {
        ClearFood();
        food = new FoodWindow(position);
        food.Show();
        eater = pets
            .Where(pet => !pet.IsBusy)
            .OrderBy(pet => DistanceSquared(
                new Point(pet.Left + PetWidth / 2, pet.Top + PetHeight / 2),
                position
            ))
            .FirstOrDefault();
        if (eater is null)
        {
            ClearFood();
            return;
        }
        eater.FoodTarget = position;
        eatingUntil = default;
    }

    private void ClearFood()
    {
        food?.Close();
        food = null;
        eater = null;
        eatingUntil = default;
    }

    private void BeginDadSequence()
    {
        if (pets.Count == 0)
            return;
        ClearFood();
        dadSequence = true;
        dadSpeechUntil = default;
        foreach (var pet in pets)
        {
            pet.IsDadLanding = true;
            pet.IsBusy = false;
            pet.VelocityX = 0;
            pet.VelocityY = 0;
            pet.FoodTarget = null;
            pet.SetFrame(sprites.Frames[(int)Pose.Crouch], pet.FacingRight);
        }
    }

    private void UploadSprites()
    {
        var dialog = new OpenFileDialog
        {
            Title = L.T("選擇 4×2 精靈圖", "Choose a 4×2 Sprite Sheet"),
            Filter = L.T("圖片檔案|*.png;*.jpg;*.jpeg;*.bmp", "Image files|*.png;*.jpg;*.jpeg;*.bmp")
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
            Title = L.T("懶人模式：選擇清楚的臉部照片", "Easy Mode: Choose a Clear Face Photo"),
            Filter = L.T("圖片檔案|*.png;*.jpg;*.jpeg;*.bmp", "Image files|*.png;*.jpg;*.jpeg;*.bmp")
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
            pet.SetFrame(sprites.Frames[(int)Pose.Crouch], pet.FacingRight);
    }

    private void OpenSpriteDirectory()
    {
        Directory.CreateDirectory(sprites.SpriteDirectory);
        Process.Start(new ProcessStartInfo("explorer.exe", sprites.SpriteDirectory) { UseShellExecute = true });
    }

    private static void ShowAbout()
    {
        var about = new AboutWindow();
        about.Show();
        about.Activate();
    }

    private static double DistanceSquared(Point a, Point b)
    {
        var dx = a.X - b.X;
        var dy = a.Y - b.Y;
        return dx * dx + dy * dy;
    }

    private static double Clamp(double value, double minimum, double maximum) =>
        Math.Min(maximum, Math.Max(minimum, value));

    private double? FindLandingSurface(PetWindow pet, double previousBottom)
    {
        if (pet.VelocityY < 0)
            return null;
        var currentBottom = pet.Top + PetHeight;
        var petLeft = pet.Left + 24;
        var petRight = pet.Left + PetWidth - 24;
        return obstacles
            .Where(rectangle =>
                petRight > rectangle.Left &&
                petLeft < rectangle.Right &&
                previousBottom <= rectangle.Top + 7 &&
                currentBottom >= rectangle.Top
            )
            .Select(rectangle => (double?)rectangle.Top)
            .OrderBy(value => value)
            .FirstOrDefault();
    }

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
        movementTimer.Stop();
        behaviorTimer.Stop();
        ClearFood();
        foreach (var pet in pets.ToArray())
            pet.Close();
        pets.Clear();
        trayIcon.Visible = false;
        trayIcon.Dispose();
    }
}
