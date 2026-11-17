using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Models.Scaffold;

[Table("Universidad", Schema = "VidaU")]
[Index("Correo", Name = "UQ_Universidad_Correo", IsUnique = true)]
public partial class Universidad
{
    [Key]
    [Column("idUniversidad")]
    public int IdUniversidad { get; set; }

    [StringLength(150)]
    [Unicode(false)]
    public string Nombre { get; set; } = null!;

    [StringLength(150)]
    [Unicode(false)]
    public string Correo { get; set; } = null!;

    [StringLength(20)]
    [Unicode(false)]
    public string Estado { get; set; } = null!;

    [StringLength(20)]
    [Unicode(false)]
    public string? Telefono { get; set; }

    [InverseProperty("IdUniversidadNavigation")]
    public virtual ICollection<Sede> Sedes { get; set; } = new List<Sede>();

    [InverseProperty("IdUniversidadNavigation")]
    public virtual ICollection<Suscripcion> Suscripcions { get; set; } = new List<Suscripcion>();

    [ForeignKey("IdUniversidad")]
    [InverseProperty("IdUniversidads")]
    public virtual ICollection<Profesor> IdProfesors { get; set; } = new List<Profesor>();
}
