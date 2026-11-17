using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Models.Scaffold;

[Table("Evaluacion", Schema = "VidaU")]
public partial class Evaluacion
{
    [Key]
    [Column("idEvaluacion")]
    public int IdEvaluacion { get; set; }

    [Column("idResennia")]
    public int IdResennia { get; set; }

    [Column(TypeName = "decimal(2, 1)")]
    public decimal Calificacion { get; set; }

    [StringLength(500)]
    [Unicode(false)]
    public string? Comentario { get; set; }

    [ForeignKey("IdResennia")]
    [InverseProperty("Evaluacions")]
    public virtual Resennium IdResenniaNavigation { get; set; } = null!;
}
