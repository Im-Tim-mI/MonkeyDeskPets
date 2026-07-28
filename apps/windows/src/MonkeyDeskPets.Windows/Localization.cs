using System.Globalization;

namespace MonkeyDeskPets.Windows;

internal static class L
{
    // 依專案規格：所有中文語系均使用繁體中文，其餘語系使用英文。
    internal static bool IsChinese =>
        CultureInfo.CurrentUICulture.Name.StartsWith("zh", StringComparison.OrdinalIgnoreCase);

    internal static string T(string traditionalChinese, string english) =>
        IsChinese ? traditionalChinese : english;
}
