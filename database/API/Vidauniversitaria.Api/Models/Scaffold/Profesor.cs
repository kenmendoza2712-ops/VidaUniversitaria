using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Models.Scaffold;

[Table("Profesor", Schema = "VidaU")]
[Index("Correo", Name = "UQ_Profesor_Correo", IsUnique = true)]
public partial class Profesor
{
    [Key]
    [Column("idProfesor")]
    public int IdProfesor { get; set; }

    [StringLength(100)]
    [Unicode(false)]
    public string Nombre { get; set; } = null!;

    [StringLength(100)]
    [Unicode(false)]
    public string Apellido { get; set; } = null!;

    [StringLength(150)]
    [Unicode(false)]
    public string Correo { get; set; } = null!;

    [InverseProperty("IdProfesorNavigation")]
    public virtual ICollection<Leccion> Leccions { get; set; } = new List<Leccion>();

    [ForeignKey("IdProfesor")]
    [InverseProperty("IdProfesors")]
    public virtual ICollection<Universidad> IdUniversidads { get; set; } = new List<Universidad>();
}
