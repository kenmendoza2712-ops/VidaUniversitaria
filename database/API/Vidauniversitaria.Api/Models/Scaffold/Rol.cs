using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Models.Scaffold;

[Table("Rol", Schema = "VidaU")]
[Index("Nombre", Name = "UQ_Rol_Nombre", IsUnique = true)]
public partial class Rol
{
    [Key]
    [Column("idRol")]
    public int IdRol { get; set; }

    [StringLength(50)]
    [Unicode(false)]
    public string Nombre { get; set; } = null!;

    [StringLength(200)]
    [Unicode(false)]
    public string? Descripcion { get; set; }

    [InverseProperty("IdRolNavigation")]
    public virtual ICollection<Usuario> Usuarios { get; set; } = new List<Usuario>();
}
