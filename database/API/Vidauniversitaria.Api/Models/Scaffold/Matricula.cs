using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Models.Scaffold;

[Table("Matricula", Schema = "VidaU")]
public partial class Matricula
{
    [Key]
    [Column("idMatricula")]
    public int IdMatricula { get; set; }

    [Column("idEstudiante")]
    public int IdEstudiante { get; set; }

    public DateOnly FechaMatricula { get; set; }

    [StringLength(20)]
    [Unicode(false)]
    public string Estado { get; set; } = null!;

    [ForeignKey("IdEstudiante")]
    [InverseProperty("Matriculas")]
    public virtual Estudiante IdEstudianteNavigation { get; set; } = null!;
}
