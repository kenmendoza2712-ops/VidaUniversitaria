using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Models.Scaffold;

[Table("Resennia", Schema = "VidaU")]
[Index("IdEstudiante", "IdLeccion", Name = "UQ_Resennia_Estudiante_Leccion", IsUnique = true)]
public partial class Resennium
{
    [Key]
    [Column("idResennia")]
    public int IdResennia { get; set; }

    [Column("idLeccion")]
    public int IdLeccion { get; set; }

    [Column("idEstudiante")]
    public int IdEstudiante { get; set; }

    [StringLength(20)]
    [Unicode(false)]
    public string Estado { get; set; } = null!;

    public bool EsAnonima { get; set; }

    [StringLength(150)]
    [Unicode(false)]
    public string NombreCurso { get; set; } = null!;

    [Column(TypeName = "datetime")]
    public DateTime FechaResennia { get; set; }

    [StringLength(200)]
    [Unicode(false)]
    public string NombreProfesor { get; set; } = null!;

    [InverseProperty("IdResenniaNavigation")]
    public virtual ICollection<Evaluacion> Evaluacions { get; set; } = new List<Evaluacion>();

    [ForeignKey("IdEstudiante")]
    [InverseProperty("Resennia")]
    public virtual Estudiante IdEstudianteNavigation { get; set; } = null!;

    [ForeignKey("IdLeccion")]
    [InverseProperty("Resennia")]
    public virtual Leccion IdLeccionNavigation { get; set; } = null!;
}
