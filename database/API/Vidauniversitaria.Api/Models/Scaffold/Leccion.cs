using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Models.Scaffold;

[Table("Leccion", Schema = "VidaU")]
public partial class Leccion
{
    [Key]
    [Column("idLeccion")]
    public int IdLeccion { get; set; }

    [Column("idCurso")]
    public int IdCurso { get; set; }

    [Column("idProfesor")]
    public int IdProfesor { get; set; }

    [StringLength(100)]
    [Unicode(false)]
    public string Horario { get; set; } = null!;

    [StringLength(50)]
    [Unicode(false)]
    public string? Aula { get; set; }

    public int Cupo { get; set; }

    [ForeignKey("IdCurso")]
    [InverseProperty("Leccions")]
    public virtual Curso IdCursoNavigation { get; set; } = null!;

    [ForeignKey("IdProfesor")]
    [InverseProperty("Leccions")]
    public virtual Profesor IdProfesorNavigation { get; set; } = null!;

    [InverseProperty("IdLeccionNavigation")]
    public virtual ICollection<Resennium> Resennia { get; set; } = new List<Resennium>();
}
