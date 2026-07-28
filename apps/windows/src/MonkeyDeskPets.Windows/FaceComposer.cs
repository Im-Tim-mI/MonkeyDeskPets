using System.IO;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using WpfPoint = System.Windows.Point;

namespace MonkeyDeskPets.Windows;

internal static class FaceComposer
{
    private readonly record struct FaceTarget(Rect NormalizedRect, double AngleRadians);

    // 與 macOS 版本使用相同的八個臉部位置及旋轉角度。
    private static readonly FaceTarget[] Targets =
    [
        new(new Rect(0.171, 0.086, 0.047, 0.103), 0),
        new(new Rect(0.387, 0.089, 0.047, 0.103), 0),
        new(new Rect(0.575, 0.032, 0.046, 0.102), -0.20),
        new(new Rect(0.834, 0.108, 0.046, 0.103), 0),
        new(new Rect(0.101, 0.543, 0.049, 0.107), 0),
        new(new Rect(0.374, 0.520, 0.048, 0.104), -0.12),
        new(new Rect(0.594, 0.531, 0.050, 0.108), 0.12),
        new(new Rect(0.911, 0.699, 0.051, 0.108), -1.42)
    ];

    internal static bool TryGenerate(
        string facePhotoPath,
        string templatePath,
        out BitmapSource generated,
        out string error
    )
    {
        generated = null!;
        error = "";
        try
        {
            var photo = LoadBitmap(facePhotoPath, 2400);
            var template = LoadBitmap(templatePath, 0);
            if (!TryDetectLargestFace(photo, out var faceRectangle))
            {
                error = L.T(
                    "照片中找不到清楚的正面臉部，請使用光線充足、臉部完整且背景單純的照片。",
                    "No clear frontal face was found. Use a well-lit photo with a complete face and a simple background."
                );
                return false;
            }

            var croppedFace = new CroppedBitmap(photo, ToPixelRect(faceRectangle, photo));
            croppedFace.Freeze();
            generated = Compose(croppedFace, template);
            return true;
        }
        catch (Exception exception)
        {
            error = L.T("臉部圖片處理失敗：", "Face image processing failed: ") + exception.Message;
            return false;
        }
    }

    internal static void SavePng(BitmapSource image, string path)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        using var output = File.Create(path);
        var encoder = new PngBitmapEncoder();
        encoder.Frames.Add(BitmapFrame.Create(image));
        encoder.Save(output);
    }

    private static BitmapSource LoadBitmap(string path, int decodePixelWidth)
    {
        if (!File.Exists(path))
            throw new FileNotFoundException(path);
        var image = new BitmapImage();
        image.BeginInit();
        image.CacheOption = BitmapCacheOption.OnLoad;
        if (decodePixelWidth > 0)
            image.DecodePixelWidth = decodePixelWidth;
        image.UriSource = new Uri(path, UriKind.Absolute);
        image.EndInit();
        image.Freeze();
        return image;
    }

    private static bool TryDetectLargestFace(BitmapSource photo, out Rect face)
    {
        face = Rect.Empty;
        var scale = Math.Min(1d, 360d / Math.Max(photo.PixelWidth, photo.PixelHeight));
        var sampleWidth = Math.Max(1, (int)Math.Round(photo.PixelWidth * scale));
        var sampleHeight = Math.Max(1, (int)Math.Round(photo.PixelHeight * scale));
        var sampled = new TransformedBitmap(
            new FormatConvertedBitmap(photo, PixelFormats.Bgra32, null, 0),
            new ScaleTransform(
                sampleWidth / (double)photo.PixelWidth,
                sampleHeight / (double)photo.PixelHeight
            )
        );
        sampled.Freeze();
        sampleWidth = sampled.PixelWidth;
        sampleHeight = sampled.PixelHeight;

        var stride = sampleWidth * 4;
        var pixels = new byte[stride * sampleHeight];
        sampled.CopyPixels(pixels, stride, 0);
        var mask = new bool[sampleWidth * sampleHeight];
        for (var y = 0; y < sampleHeight; y++)
        for (var x = 0; x < sampleWidth; x++)
        {
            var index = y * stride + x * 4;
            mask[y * sampleWidth + x] = IsSkin(
                pixels[index + 2],
                pixels[index + 1],
                pixels[index]
            );
        }

        var visited = new bool[mask.Length];
        var queue = new Queue<int>();
        var bestScore = 0d;
        Rect best = Rect.Empty;

        void Visit(int x, int y)
        {
            if (x < 0 || y < 0 || x >= sampleWidth || y >= sampleHeight)
                return;
            var index = y * sampleWidth + x;
            if (!visited[index] && mask[index])
            {
                visited[index] = true;
                queue.Enqueue(index);
            }
        }

        for (var start = 0; start < mask.Length; start++)
        {
            if (!mask[start] || visited[start])
                continue;
            visited[start] = true;
            queue.Enqueue(start);
            var count = 0;
            var minX = sampleWidth;
            var maxX = 0;
            var minY = sampleHeight;
            var maxY = 0;
            while (queue.Count > 0)
            {
                var current = queue.Dequeue();
                var x = current % sampleWidth;
                var y = current / sampleWidth;
                count++;
                minX = Math.Min(minX, x);
                maxX = Math.Max(maxX, x);
                minY = Math.Min(minY, y);
                maxY = Math.Max(maxY, y);
                Visit(x - 1, y);
                Visit(x + 1, y);
                Visit(x, y - 1);
                Visit(x, y + 1);
            }

            var width = maxX - minX + 1;
            var height = maxY - minY + 1;
            var ratio = width / (double)height;
            if (count < sampleWidth * sampleHeight * 0.002 || ratio < 0.45 || ratio > 1.8)
                continue;
            if (width > sampleWidth * 0.72 || height > sampleHeight * 0.72)
                continue;

            var centerX = (minX + maxX) / 2d;
            var centerY = (minY + maxY) / 2d;
            var centerDistance = Math.Sqrt(
                Math.Pow(centerX / sampleWidth - 0.5, 2) +
                Math.Pow(centerY / sampleHeight - 0.42, 2)
            );
            var score = count * Math.Max(0.35, 1.25 - centerDistance);
            if (score > bestScore)
            {
                bestScore = score;
                best = new Rect(minX, minY, width, height);
            }

        }

        if (best.IsEmpty)
            return false;

        // 最大膚色區可能一路連到脖子；使用區域上緣與臉寬估算頭部，
        // 避免把衣領或胸口一起裁入。
        var estimatedFaceWidth = Math.Min(best.Width, best.Height * 0.84);
        var cropWidth = estimatedFaceWidth * 1.18;
        var cropHeight = estimatedFaceWidth * 1.30;
        var expanded = new Rect(
            best.X + best.Width / 2 - cropWidth / 2,
            best.Y - estimatedFaceWidth * 0.18,
            cropWidth,
            cropHeight
        );
        expanded.Intersect(new Rect(0, 0, sampleWidth, sampleHeight));
        face = new Rect(
            expanded.X * photo.PixelWidth / sampleWidth,
            expanded.Y * photo.PixelHeight / sampleHeight,
            expanded.Width * photo.PixelWidth / sampleWidth,
            expanded.Height * photo.PixelHeight / sampleHeight
        );
        return face.Width >= 24 && face.Height >= 24;
    }

    private static bool IsSkin(byte red, byte green, byte blue)
    {
        var maximum = Math.Max(red, Math.Max(green, blue));
        var minimum = Math.Min(red, Math.Min(green, blue));
        var rgbRule = red > 70 && green > 35 && blue > 15 &&
                      maximum - minimum > 12 && red > green && red > blue;
        var cb = 128 - 0.168736 * red - 0.331264 * green + 0.5 * blue;
        var cr = 128 + 0.5 * red - 0.418688 * green - 0.081312 * blue;
        return rgbRule && cb is >= 72 and <= 135 && cr is >= 130 and <= 180;
    }

    private static Int32Rect ToPixelRect(Rect rectangle, BitmapSource image)
    {
        var x = Math.Clamp((int)Math.Floor(rectangle.X), 0, image.PixelWidth - 1);
        var y = Math.Clamp((int)Math.Floor(rectangle.Y), 0, image.PixelHeight - 1);
        var right = Math.Clamp((int)Math.Ceiling(rectangle.Right), x + 1, image.PixelWidth);
        var bottom = Math.Clamp((int)Math.Ceiling(rectangle.Bottom), y + 1, image.PixelHeight);
        return new Int32Rect(x, y, right - x, bottom - y);
    }

    private static BitmapSource Compose(BitmapSource face, BitmapSource template)
    {
        var width = template.PixelWidth;
        var height = template.PixelHeight;
        var visual = new DrawingVisual();
        using (var drawing = visual.RenderOpen())
        {
            drawing.DrawImage(template, new Rect(0, 0, width, height));
            foreach (var target in Targets)
            {
                var rectangle = new Rect(
                    target.NormalizedRect.X * width,
                    target.NormalizedRect.Y * height,
                    target.NormalizedRect.Width * width,
                    target.NormalizedRect.Height * height
                );
                var center = new WpfPoint(rectangle.X + rectangle.Width / 2, rectangle.Y + rectangle.Height / 2);
                drawing.PushTransform(new RotateTransform(
                    -target.AngleRadians * 180 / Math.PI,
                    center.X,
                    center.Y
                ));
                drawing.PushClip(new EllipseGeometry(
                    center,
                    rectangle.Width / 2 + 4,
                    rectangle.Height / 2 + 4
                ));
                drawing.DrawImage(face, rectangle);
                drawing.Pop();
                drawing.Pop();
            }
        }

        var result = new RenderTargetBitmap(width, height, 96, 96, PixelFormats.Pbgra32);
        result.Render(visual);
        result.Freeze();
        return result;
    }
}
