using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Models.Scaffold;

[Table("Curso", Schema = "VidaU")]
public partial class Curso
{
    [Key]
    [Column("idCurso")]
    public int IdCurso { get; set; }

    [StringLength(150)]
    [Unicode(false)]
    public string Nombre { get; set; } = null!;

    [StringLength(300)]
    [Unicode(false)]
    public string? Descripcion { get; set; }

    public int Creditos { get; set; }

    [InverseProperty("IdCursoNavigation")]
    public virtual ICollection<Leccion> Leccions { get; set; } = new List<Leccion>();

    [ForeignKey("IdCurso")]
    [InverseProperty("IdCursos")]
    public virtual ICollection<Carrera> IdCarreras { get; set; } = new List<Carrera>();
}
