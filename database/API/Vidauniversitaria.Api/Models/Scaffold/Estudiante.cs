using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Models.Scaffold;

[Table("Estudiante", Schema = "VidaU")]
[Index("Carnet", Name = "UQ_Estudiante_Carnet", IsUnique = true)]
[Index("IdUsuario", Name = "UQ_Estudiante_Usuario", IsUnique = true)]
public partial class Estudiante
{
    [Key]
    [Column("idEstudiante")]
    public int IdEstudiante { get; set; }

    [Column("idUsuario")]
    public int IdUsuario { get; set; }

    [StringLength(20)]
    [Unicode(false)]
    public string Carnet { get; set; } = null!;

    [StringLength(150)]
    [Unicode(false)]
    public string Carrera { get; set; } = null!;

    public int AnnoIngreso { get; set; }

    [ForeignKey("IdUsuario")]
    [InverseProperty("Estudiante")]
    public virtual Usuario IdUsuarioNavigation { get; set; } = null!;

    [InverseProperty("IdEstudianteNavigation")]
    public virtual ICollection<Matricula> Matriculas { get; set; } = new List<Matricula>();

    [InverseProperty("IdEstudianteNavigation")]
    public virtual ICollection<Resennium> Resennia { get; set; } = new List<Resennium>();

    [ForeignKey("IdEstudiante")]
    [InverseProperty("IdEstudiantes")]
    public virtual ICollection<Carrera> IdCarreras { get; set; } = new List<Carrera>();
}
