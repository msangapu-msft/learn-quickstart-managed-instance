using SixLabors.Fonts;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Drawing.Processing;
using SixLabors.ImageSharp.Formats.Png;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// Load font once at startup - now returns both FontFamily and path
var (fontFamily, fontPath) = LoadSystemFont();
Console.WriteLine($"Loaded font: {fontFamily.Name} from {fontPath}");

app.MapGet("/", () => "Image Demo API - Endpoints: /font-info and /aptos-image");

app.MapGet("/font-info", () => new
{
    platform = System.Runtime.InteropServices.RuntimeInformation.OSDescription,
    fontLoaded = fontFamily.Name,
    fontPath = fontPath,
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
    
    // Create fonts - main text and smaller font for path info
    var font = fontFamily.CreateFont(size);
    var pathFont = fontFamily.CreateFont(Math.Max(12, size / 4)); // Smaller font for path
    
    // Measure text bounds for main text
    var bounds = TextMeasurer.MeasureBounds(text, new TextOptions(font));
    
    // Measure text bounds for font path
    var pathText = $"Font: {fontPath}";
    var pathBounds = TextMeasurer.MeasureBounds(pathText, new TextOptions(pathFont));
    
    // Calculate image dimensions
    int width = (int)Math.Ceiling(Math.Max(bounds.Width, pathBounds.Width)) + (padding * 2);
    int height = (int)Math.Ceiling(bounds.Height + pathBounds.Height + 10) + (padding * 2); // 10px gap between texts
    
    // Create image
    using var image = new Image<Rgba32>(Math.Max(width, 10), Math.Max(height, 10));
    image.Mutate(context =>
    {
        context.Fill(Color.White);
        
        // Draw main text
        context.DrawText(text, font, Color.Black, new PointF(padding, padding));
        
        // Draw font path below main text
        float pathY = padding + bounds.Height + 10; // 10px gap
        context.DrawText(pathText, pathFont, Color.Gray, new PointF(padding, pathY));
    });
    
    // Return as PNG
    using var ms = new MemoryStream();
    image.Save(ms, new PngEncoder());
    return Results.File(ms.ToArray(), "image/png");
});

app.Run();

static (FontFamily, string) LoadSystemFont()
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
            return (collection.Add(aptosPath), aptosPath);
        }
        
        // Fall back to Arial
        var arialPath = Path.Combine(fontsDir, "Arial.ttf");
        if (File.Exists(arialPath))
        {
            Console.WriteLine($"Loading Arial from: {arialPath}");
            return (collection.Add(arialPath), arialPath);
        }
    }
    
    throw new InvalidOperationException("Could not find Aptos.ttf or Arial.ttf in Windows Fonts directory");
}