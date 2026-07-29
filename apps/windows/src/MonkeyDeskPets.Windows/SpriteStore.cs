using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace MonkeyDeskPets.Windows;

internal sealed class SpriteStore
{
    private const int Columns = 4;
    private const int Rows = 2;
    private const string EmbeddedDefaultSprites = "MonkeyDeskPets.DefaultSprites.png";
    private readonly string bundledPath = Path.Combine(AppContext.BaseDirectory, "Assets", "person-sprites.png");
    private readonly string spriteDirectory = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "MonkeyDeskPets",
        "Sprites",
        "Current"
    );
    private BitmapSource[] frames = [];

    internal IReadOnlyList<BitmapSource> Frames => frames;
    internal string SpriteDirectory => spriteDirectory;
    internal string BundledPath => bundledPath;

    internal void Load()
    {
        var custom = Path.Combine(spriteDirectory, "sprites.png");
        if (!TryLoadSheet(custom, out frames) &&
            !TryLoadSheet(bundledPath, out frames) &&
            !TryLoadEmbeddedDefault(out frames))
            throw new InvalidDataException(L.T("找不到有效的預設精靈圖。", "No valid default sprite sheet was found."));
    }

    internal bool Import(string sourcePath, out string error)
    {
        error = "";
        if (!TryReadImage(sourcePath, out var source))
        {
            error = L.T("圖片必須是可讀取的 4×2 精靈圖。", "The image must be a readable 4×2 sprite sheet.");
            return false;
        }

        Directory.CreateDirectory(spriteDirectory);
        DeleteGeneratedFaceFiles();
        var destination = Path.Combine(spriteDirectory, "sprites.png");
        var temporary = Path.Combine(spriteDirectory, "sprites.new.png");
        var processed = RemoveGreenScreenIfNeeded(source);
        if (!TrySplit(processed, out var imported))
        {
            error = L.T("圖片必須符合 4 欄×2 列（約 2:1）的版面比例。", "The image must use a 4-column × 2-row layout with an approximately 2:1 aspect ratio.");
            return false;
        }
        using (var output = File.Create(temporary))
        {
            var encoder = new PngBitmapEncoder();
            encoder.Frames.Add(BitmapFrame.Create(processed));
            encoder.Save(output);
        }
        File.Move(temporary, destination, true);
        frames = imported;
        return true;
    }

    internal void Reset()
    {
        if (Directory.Exists(spriteDirectory))
            Directory.Delete(spriteDirectory, true);
        Load();
    }

    internal bool ImportGenerated(BitmapSource sheet, string sourceFacePath, out string error)
    {
        error = "";
        if (!TrySplit(sheet, out var imported))
        {
            error = L.T("生成的精靈圖無法拆分為八格。", "The generated sprite sheet could not be split into eight frames.");
            return false;
        }

        Directory.CreateDirectory(spriteDirectory);
        DeleteGeneratedFaceFiles();
        var temporary = Path.Combine(spriteDirectory, "sprites.new.png");
        var destination = Path.Combine(spriteDirectory, "sprites.png");
        using (var output = File.Create(temporary))
        {
            var encoder = new PngBitmapEncoder();
            encoder.Frames.Add(BitmapFrame.Create(sheet));
            encoder.Save(output);
        }
        File.Move(temporary, destination, true);
        File.Copy(sourceFacePath, Path.Combine(spriteDirectory, "source-face" + Path.GetExtension(sourceFacePath)), true);
        frames = imported;
        return true;
    }

    private void DeleteGeneratedFaceFiles()
    {
        if (!Directory.Exists(spriteDirectory))
            return;
        foreach (var path in Directory.EnumerateFiles(spriteDirectory, "source-face.*"))
            File.Delete(path);
    }

    private static bool TryLoadSheet(string path, out BitmapSource[] result)
    {
        result = [];
        if (!TryReadImage(path, out var source))
            return false;
        return TrySplit(source, out result);
    }

    private static bool TryLoadEmbeddedDefault(out BitmapSource[] result)
    {
        result = [];
        try
        {
            using var stream = Assembly.GetExecutingAssembly()
                .GetManifestResourceStream(EmbeddedDefaultSprites);
            if (stream is null || !TryReadImage(stream, out var source))
                return false;
            return TrySplit(source, out result);
        }
        catch
        {
            return false;
        }
    }

    private static bool TryReadImage(string path, out BitmapSource source)
    {
        source = null!;
        if (!File.Exists(path))
            return false;
        try
        {
            using var stream = File.OpenRead(path);
            return TryReadImage(stream, out source);
        }
        catch
        {
            return false;
        }
    }

    private static bool TryReadImage(Stream stream, out BitmapSource source)
    {
        source = null!;
        try
        {
            var decoder = BitmapDecoder.Create(
                stream,
                BitmapCreateOptions.PreservePixelFormat,
                BitmapCacheOption.OnLoad
            );
            source = decoder.Frames[0];
            source.Freeze();
            return true;
        }
        catch
        {
            return false;
        }
    }

    private static bool TrySplit(BitmapSource source, out BitmapSource[] result)
    {
        result = [];
        if (source.PixelWidth < Columns || source.PixelHeight < Rows)
            return false;
        var aspectRatio = source.PixelWidth / (double)source.PixelHeight;
        if (aspectRatio < 1.8 || aspectRatio > 2.2)
            return false;

        var loaded = new BitmapSource[Columns * Rows];
        for (var row = 0; row < Rows; row++)
        for (var column = 0; column < Columns; column++)
        {
            var x0 = (int)Math.Round(column * source.PixelWidth / (double)Columns);
            var x1 = (int)Math.Round((column + 1) * source.PixelWidth / (double)Columns);
            var y0 = (int)Math.Round(row * source.PixelHeight / (double)Rows);
            var y1 = (int)Math.Round((row + 1) * source.PixelHeight / (double)Rows);
            var crop = new CroppedBitmap(
                source,
                new Int32Rect(x0, y0, x1 - x0, y1 - y0)
            );
            crop.Freeze();
            loaded[row * Columns + column] = crop;
        }

        result = loaded;
        return true;
    }

    private static BitmapSource RemoveGreenScreenIfNeeded(BitmapSource source)
    {
        var converted = new FormatConvertedBitmap(source, PixelFormats.Bgra32, null, 0);
        var width = converted.PixelWidth;
        var height = converted.PixelHeight;
        var stride = width * 4;
        var pixels = new byte[stride * height];
        converted.CopyPixels(pixels, stride, 0);

        var samples = 0;
        var greenSamples = 0;
        var step = Math.Max(1, Math.Min(width, height) / 120);
        for (var x = 0; x < width; x += step)
        {
            CountPixel(x, 0);
            CountPixel(x, height - 1);
        }
        for (var y = step; y < height - step; y += step)
        {
            CountPixel(0, y);
            CountPixel(width - 1, y);
        }

        if (samples == 0 || greenSamples / (double)samples < 0.60)
            return source;

        for (var index = 0; index < pixels.Length; index += 4)
        {
            var blue = pixels[index];
            var green = pixels[index + 1];
            var red = pixels[index + 2];
            var dominance = green - Math.Max(red, blue);
            if (green > 70 && dominance > 15)
            {
                var alpha = 255 - Math.Clamp((dominance - 15) * 5, 0, 255);
                pixels[index + 3] = (byte)Math.Min(pixels[index + 3], alpha);
                pixels[index + 1] = (byte)Math.Min(green, Math.Max(red, blue) + 18);
            }
        }

        var result = BitmapSource.Create(
            width,
            height,
            converted.DpiX,
            converted.DpiY,
            PixelFormats.Bgra32,
            null,
            pixels,
            stride
        );
        result.Freeze();
        return result;

        void CountPixel(int x, int y)
        {
            var index = y * stride + x * 4;
            var blue = pixels[index];
            var green = pixels[index + 1];
            var red = pixels[index + 2];
            samples++;
            if (green > 80 && green > red * 1.20 && green > blue * 1.20)
                greenSamples++;
        }
    }
}
