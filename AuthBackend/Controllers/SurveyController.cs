using AuthBackend.Data;
using AuthBackend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Text;
using System.Text.Json;

namespace AuthBackend.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class SurveyController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHttpClientFactory _httpClientFactory;

        public SurveyController(ApplicationDbContext context, IHttpClientFactory httpClientFactory)
        {
            _context = context;
            _httpClientFactory = httpClientFactory;
        }

        [HttpPost("submit")]
        public async Task<IActionResult> SubmitSurvey([FromBody] AuthBackend.DTOs.SurveySubmissionDto model)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            // Check if user already submitted today
            var alreadySubmitted = await _context.UserSurveys
                .AnyAsync(s => s.UserId == userId && s.DateTaken.Date == DateTime.UtcNow.Date);

            if (alreadySubmitted)
                return BadRequest(new { Message = "You have already submitted your survey for today!" });

            var survey = new UserSurvey
            {
                UserId = userId,
                Rating = model.Rating,
                DateTaken = DateTime.UtcNow
            };

            _context.UserSurveys.Add(survey);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Survey saved successfully!" });
        }

        [HttpPost("dump-to-model")]
        public async Task<IActionResult> DumpUserData()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            // 1. Fetch data and transform to Prophet format (ds and y)
            var prophetData = await _context.UserSurveys
                .Where(s => s.UserId == userId)
                .OrderBy(s => s.DateTaken)
                .Select(s => new
                {
                    ds = s.DateTaken.ToString("yyyy-MM-dd HH:mm:ss"),
                    y = s.Rating
                })
                .ToListAsync();

            if (!prophetData.Any())
                return BadRequest(new { Message = "No data available for this user." });

            // 2. Prepare the HTTP Client
            var client = _httpClientFactory.CreateClient();
            var jsonPayload = JsonSerializer.Serialize(prophetData);
            var content = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

            try
            {
                // 3. Send to your local model server
                var response = await client.PostAsync("http://localhost:5002/receive-data", content);

                if (response.IsSuccessStatusCode)
                    return Ok(new { Message = "Data dumped successfully to localhost:5002" });
                
                return StatusCode((int)response.StatusCode, "Target server rejected the data.");
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Failed to connect to localhost:5002: {ex.Message}");
            }
        }
        [HttpGet("forecast")]
        public async Task<IActionResult> GetHistory()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            // 1. Fetch ALL data directly from SQL
            var userHistory = await _context.UserSurveys
                .Where(s => s.UserId == userId)
                .OrderBy(s => s.DateTaken)
                .Select(s => new
                {
                    ds = s.DateTaken.ToString("yyyy-MM-dd HH:mm:ss"),
                    y = s.Rating
                })
                .ToListAsync();
            
            return Ok(new 
            { 
                success = true, 
                predictions = userHistory, 
                message = userHistory.Any() ? "History loaded" : "No data available"
            });
        }

        [HttpGet("predict-future")]
        public async Task<IActionResult> PredictFuture()
        {
             var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            // 1. Fetch data for context
            var userHistory = await _context.UserSurveys
                .Where(s => s.UserId == userId)
                .OrderBy(s => s.DateTaken)
                .Select(s => new
                {
                    ds = s.DateTaken.ToString("yyyy-MM-dd HH:mm:ss"),
                    y = s.Rating
                })
                .ToListAsync();

             if (userHistory.Count < 2)
                 return BadRequest(new { Message = "Not enough data for prediction. Need at least 2 days of history." });

            // 2. Prepare Payload for Python
            var payload = new
            {
                data = userHistory,
                periods = 7 
            };

            var client = _httpClientFactory.CreateClient();
            var jsonPayload = JsonSerializer.Serialize(payload);
            var content = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

            try
            {
                // 3. Call Python Microservice
                var response = await client.PostAsync("http://localhost:5002/predict", content);
                
                if (response.IsSuccessStatusCode)
                {
                    var responseString = await response.Content.ReadAsStringAsync();
                    return Content(responseString, "application/json");
                }
                
                var errorBody = await response.Content.ReadAsStringAsync();
                return StatusCode((int)response.StatusCode, new { Message = "Prediction service failed", Details = errorBody });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { Message = "Failed to connect to prediction service", Error = ex.Message });
            }
        }
        [HttpGet("staffing")]
        public async Task<IActionResult> GetStaffingOptimization()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            // 1. Get most recent survey rating to use as max_staff
            var latestSurvey = await _context.UserSurveys
                .Where(s => s.UserId == userId)
                .OrderByDescending(s => s.DateTaken)
                .FirstOrDefaultAsync();

            if (latestSurvey == null)
                return BadRequest(new { Message = "No survey data found. Please submit a survey first to set your staffing capacity." });

            int maxStaff = latestSurvey.Rating;

            // 2. Prepare payload for Python
            var payload = new
            {
                max_staff = maxStaff,
                day = DateTime.Now.DayOfWeek.ToString() // Send current day
            };

            var client = _httpClientFactory.CreateClient();
            var jsonPayload = JsonSerializer.Serialize(payload);
            var content = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

            try
            {
                // 3. Call Python Microservice
                var response = await client.PostAsync("http://localhost:5002/staffing", content);

                if (response.IsSuccessStatusCode)
                {
                    var responseString = await response.Content.ReadAsStringAsync();
                    return Content(responseString, "application/json");
                }

                var errorBody = await response.Content.ReadAsStringAsync();
                return StatusCode((int)response.StatusCode, new { Message = "Staffing service failed", Details = errorBody });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { Message = "Failed to connect to staffing service", Error = ex.Message });
            }
        }
    }
}