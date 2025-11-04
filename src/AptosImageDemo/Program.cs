using SixLabors.Fonts;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Drawing.Processing;
using SixLabors.ImageSharp.Formats.Png;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// Load font once at startup
var fontFamily = LoadSystemFont();
Console.WriteLine($"Loaded font: {fontFamily.Name}");

app.MapGet("/", () => "Image Demo API - Endpoints: /font-info and /aptos-image");

app.MapGet("/font-info", () => new
{
    platform = System.Runtime.InteropServices.RuntimeInformation.OSDescription,
    fontLoaded = fontFamily.Name,
    isWindows = OperatingSystem.IsWindows()
});

app.MapGet("/aptos-image", (HttpContext ctx) =>
{
    // Parse query parameters
    string text = ctx.Request.Query["text"].FirstOrDefault() ?? "Hello World";
    if (!int.TryParse(ctx.Request.Query["size"], out int size))
        size = 48;
    size = Math.Clamp(size, 8, 200);
    
    if (!int.TryParse(ctx.Request.Query["pad"], out int padding))
        padding = 20;
    padding = Math.Clamp(padding, 0, 100);
    
    // Create font
    var font = fontFamily.CreateFont(size);
    
    // Measure text bounds
    var bounds = TextMeasurer.MeasureBounds(text, new TextOptions(font));
    int width = (int)Math.Ceiling(bounds.Width) + (padding * 2);
    int height = (int)Math.Ceiling(bounds.Height) + (padding * 2);
    
    // Create image
    using var image = new Image<Rgba32>(Math.Max(width, 10), Math.Max(height, 10));
    image.Mutate(context =>
    {
        context.Fill(Color.White);
        context.DrawText(text, font, Color.Black, new PointF(padding, padding));
    });
    
    // Return as PNG
    using var ms = new MemoryStream();
    image.Save(ms, new PngEncoder());
    return Results.File(ms.ToArray(), "image/png");
});

app.Run();

static FontFamily LoadSystemFont()
{
    var collection = new FontCollection();
    
    // Windows - try to load Aptos or Arial
    if (OperatingSystem.IsWindows())
    {
        var fontsDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), "Fonts");
        
        // Try Aptos first
        var aptosPath = Path.Combine(fontsDir, "Aptos.ttf");
        if (File.Exists(aptosPath))
        {
            Console.WriteLine($"Loading Aptos from: {aptosPath}");
            return collection.Add(aptosPath);
        }
        
        // Fall back to Arial
        var arialPath = Path.Combine(fontsDir, "Arial.ttf");
        if (File.Exists(arialPath))
        {
            Console.WriteLine($"Loading Arial from: {arialPath}");
            return collection.Add(arialPath);
        }
    }
    
    // macOS - look for .ttf files (avoid .ttc)
    if (OperatingSystem.IsMacOS())
    {
        // Try specific TTF files that are commonly available
        string[] ttfCandidates = [
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/System/Library/Fonts/Supplemental/Verdana.ttf",
            "/System/Library/Fonts/Supplemental/Georgia.ttf",
            "/System/Library/Fonts/Supplemental/Courier New.ttf",
            "/Library/Fonts/Arial.ttf",
            "/System/Library/Fonts/Avenir.ttc",  // Some .ttc might work
            "/System/Library/Fonts/Avenir Next.ttc"
        ];
        
        foreach (var path in ttfCandidates)
        {
            if (File.Exists(path) && path.EndsWith(".ttf"))
            {
                try
                {
                    Console.WriteLine($"Trying to load: {path}");
                    return collection.Add(path);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Failed to load {path}: {ex.Message}");
                }
            }
        }
        
        // Find ANY .ttf file in system fonts
        Console.WriteLine("Searching for any .ttf file in /System/Library/Fonts/Supplemental/");
        var supplementalFonts = Directory.GetFiles("/System/Library/Fonts/Supplemental/", "*.ttf", SearchOption.TopDirectoryOnly);
        foreach (var font in supplementalFonts)
        {
            try
            {
                Console.WriteLine($"Trying: {font}");
                return collection.Add(font);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed: {ex.Message}");
            }
        }
        
        // Try Library Fonts
        if (Directory.Exists("/Library/Fonts"))
        {
            var libraryFonts = Directory.GetFiles("/Library/Fonts", "*.ttf", SearchOption.TopDirectoryOnly);
            foreach (var font in libraryFonts)
            {
                try
                {
                    Console.WriteLine($"Trying: {font}");
                    return collection.Add(font);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Failed: {ex.Message}");
                }
            }
        }
    }
    
    // Linux - use DejaVu Sans
    if (OperatingSystem.IsLinux())
    {
        var dejavuPath = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf";
        if (File.Exists(dejavuPath))
        {
            Console.WriteLine($"Loading DejaVu Sans from: {dejavuPath}");
            return collection.Add(dejavuPath);
        }
    }
    
    throw new InvalidOperationException("Could not find any compatible .ttf font file on this system");
}
