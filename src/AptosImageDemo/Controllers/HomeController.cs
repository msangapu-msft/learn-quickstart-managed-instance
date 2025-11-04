using System.Web.Http;

namespace AptosImageDemo.Controllers
{
    public class HomeController : ApiController
    {
        [HttpGet]
        [Route("")]
        public IHttpActionResult Get()
        {
            return Ok("Image Demo API - Endpoints: /font-info and /aptos-image");
        }

        [HttpGet]
        [Route("font-info")]
        public IHttpActionResult GetFontInfo()
        {
            var fontInfo = Helpers.FontLoader.GetFontInfo();
            return Ok(new
            {
                platform = System.Environment.OSVersion.ToString(),
                fontLoaded = fontInfo.FontFamily.Name,
                fontPath = fontInfo.FontPath,
                isWindows = System.Environment.OSVersion.Platform == System.PlatformID.Win32NT
            });
        }
    }
}