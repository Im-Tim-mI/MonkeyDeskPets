//
// MonkeyDeskPets for Windows
// Copyright © 2026 廷廷小教室、廷廷的家（Tim945）
//
// Licensed under the MonkeyDeskPets Noncommercial License 1.0,
// based on PolyForm Noncommercial License 1.0.0.
// See LICENSE, NOTICE, and ADDITIONAL-TERMS-zh-TW.txt.
//

using System.Windows;
using WpfApplication = System.Windows.Application;

namespace MonkeyDeskPets.Windows;

public partial class App : WpfApplication
{
    private DesktopPetController? controller;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        controller = new DesktopPetController();
        controller.Start();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        controller?.Dispose();
        base.OnExit(e);
    }
}
