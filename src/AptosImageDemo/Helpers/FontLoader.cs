using System;
using System.IO;
using SixLabors.Fonts;

namespace AptosImageDemo.Helpers
{
    public class FontLoader
    {
        private static FontFamily _fontFamily;
        private static string _fontPath;
        private static readonly object _lock = new object();

        public class FontInfo
        {
            public FontFamily FontFamily { get; set; }
            public string FontPath { get; set; }
        }

        public static FontInfo GetFontInfo()
        {
            if (_fontFamily == null)
            {
                lock (_lock)
                {
                    if (_fontFamily == null)
                    {
                        LoadFont();
                    }
                }
            }

            return new FontInfo
            {
                FontFamily = _fontFamily,
                FontPath = _fontPath
            };
        }

        private static void LoadFont()
        {
            var collection = new FontCollection();

            // Check if running on Windows
            if (Environment.OSVersion.Platform == PlatformID.Win32NT)
            {
                var fontsDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), "Fonts");

                // Try Aptos first
                var aptosPath = Path.Combine(fontsDir, "Aptos.ttf");
                if (File.Exists(aptosPath))
                {
                    Console.WriteLine($"Loading Aptos from: {aptosPath}");
                    _fontFamily = collection.Install(aptosPath);
                    _fontPath = aptosPath;
                    return;
                }

                // Fall back to Arial
                var arialPath = Path.Combine(fontsDir, "Arial.ttf");
                if (File.Exists(arialPath))
                {
                    Console.WriteLine($"Loading Arial from: {arialPath}");
                    _fontFamily = collection.Install(arialPath);
                    _fontPath = arialPath;
                    return;
                }
            }

            throw new InvalidOperationException("Could not find Aptos.ttf or Arial.ttf in Windows Fonts directory");
        }
    }
}