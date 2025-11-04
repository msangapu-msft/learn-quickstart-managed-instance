using System;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Web.Http;
using SixLabors.Fonts;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Drawing.Processing;
using SixLabors.ImageSharp.Formats.Png;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;
using SixLabors.Primitives;

namespace AptosImageDemo.Controllers
{
    public class ImageController : ApiController
    {
        [HttpGet]
        [Route("aptos-image")]
        public HttpResponseMessage GetAptosImage(string text = "Hello World", int size = 48, int pad = 20)
        {
            try
            {
                // Clamp values
                size = Math.Max(8, Math.Min(200, size));
                pad = Math.Max(0, Math.Min(100, pad));

                var fontInfo = Helpers.FontLoader.GetFontInfo();
                var fontFamily = fontInfo.FontFamily;
                var fontPath = fontInfo.FontPath;

                // Create fonts - main text and smaller font for path info
                var font = fontFamily.CreateFont(size);
                var pathFont = fontFamily.CreateFont(Math.Max(12, size / 4));

                // Measure text bounds for main text
                var bounds = TextMeasurer.Measure(text, new RendererOptions(font));

                // Measure text bounds for font path
                var pathText = $"Font: {fontPath}";
                var pathBounds = TextMeasurer.Measure(pathText, new RendererOptions(pathFont));

                // Calculate image dimensions
                int width = (int)Math.Ceiling(Math.Max(bounds.Width, pathBounds.Width)) + (pad * 2);
                int height = (int)Math.Ceiling(bounds.Height + pathBounds.Height + 10) + (pad * 2);

                // Create image
                using (var image = new Image<Rgba32>(Math.Max(width, 10), Math.Max(height, 10)))
                {
                    image.Mutate(context =>
                    {
                        context.Fill(Color.White);

                        // Draw main text
                        context.DrawText(text, font, Color.Black, new PointF(pad, pad));

                        // Draw font path below main text
                        float pathY = pad + bounds.Height + 10;
                        context.DrawText(pathText, pathFont, Color.Gray, new PointF(pad, pathY));
                    });

                    // Save to memory stream
                    var ms = new MemoryStream();
                    image.Save(ms, new PngEncoder());
                    ms.Position = 0;

                    var response = new HttpResponseMessage(HttpStatusCode.OK)
                    {
                        Content = new ByteArrayContent(ms.ToArray())
                    };
                    response.Content.Headers.ContentType = new MediaTypeHeaderValue("image/png");

                    return response;
                }
            }
            catch (Exception ex)
            {
                return Request.CreateErrorResponse(HttpStatusCode.InternalServerError, ex.Message);
            }
        }
    }
}