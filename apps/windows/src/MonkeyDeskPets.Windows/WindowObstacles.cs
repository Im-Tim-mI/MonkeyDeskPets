using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows;

namespace MonkeyDeskPets.Windows;

internal static class WindowObstacles
{
    private delegate bool EnumWindowsProc(nint window, nint parameter);

    [StructLayout(LayoutKind.Sequential)]
    private struct NativeRect
    {
        internal int Left;
        internal int Top;
        internal int Right;
        internal int Bottom;
    }

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc callback, nint parameter);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(nint window);

    [DllImport("user32.dll")]
    private static extern bool IsIconic(nint window);

    [DllImport("user32.dll")]
    private static extern bool GetWindowRect(nint window, out NativeRect rectangle);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(nint window, out uint processId);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetWindowText(nint window, StringBuilder text, int maximum);

    internal static IReadOnlyList<Rect> ReadVisibleWindows()
    {
        var result = new List<Rect>();
        var ownProcess = (uint)Environment.ProcessId;
        EnumWindows((window, _) =>
        {
            if (!IsWindowVisible(window) || IsIconic(window))
                return true;
            GetWindowThreadProcessId(window, out var processId);
            if (processId == ownProcess)
                return true;
            var title = new StringBuilder(2);
            if (GetWindowText(window, title, title.Capacity) == 0)
                return true;
            if (!GetWindowRect(window, out var rectangle))
                return true;
            var width = rectangle.Right - rectangle.Left;
            var height = rectangle.Bottom - rectangle.Top;
            // 與 macOS 版相同：忽略過小的浮動面板與系統碎片視窗。
            if (width > 120 && height > 80)
                result.Add(new Rect(rectangle.Left, rectangle.Top, width, height));
            return true;
        }, 0);
        return result;
    }
}
