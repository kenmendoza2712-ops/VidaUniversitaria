using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Models.Scaffold;

[Table("Carrera", Schema = "VidaU")]
public partial class Carrera
{
    [Key]
    [Column("idCarrera")]
    public int IdCarrera { get; set; }

    [StringLength(150)]
    [Unicode(false)]
    public string Nombre { get; set; } = null!;

    [StringLength(300)]
    [Unicode(false)]
    public string? Descripcion { get; set; }

    [ForeignKey("IdCarrera")]
    [InverseProperty("IdCarreras")]
    public virtual ICollection<Curso> IdCursos { get; set; } = new List<Curso>();

    [ForeignKey("IdCarrera")]
    [InverseProperty("IdCarreras")]
    public virtual ICollection<Estudiante> IdEstudiantes { get; set; } = new List<Estudiante>();

    [ForeignKey("IdCarrera")]
    [InverseProperty("IdCarreras")]
    public virtual ICollection<Sede> IdSedes { get; set; } = new List<Sede>();
}
