using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AuthBackend.Models
{
    public class UserSurvey
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string UserId { get; set; } = string.Empty;

        [Required]
        public DateTime DateTaken { get; set; } = DateTime.UtcNow;

        [Required]
        public int Rating { get; set; }

        // This links the survey to the User table
        [ForeignKey("UserId")]
        public virtual ApplicationUser? User { get; set; }
    }
}