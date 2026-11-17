using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Models.Scaffold;

[Table("Usuario", Schema = "VidaU")]
[Index("Correo", Name = "UQ_Usuario_Correo", IsUnique = true)]
public partial class Usuario
{
    [Key]
    [Column("idUsuario")]
    public int IdUsuario { get; set; }

    [Column("idRol")]
    public int IdRol { get; set; }

    [StringLength(100)]
    [Unicode(false)]
    public string Nombre { get; set; } = null!;

    [StringLength(100)]
    [Unicode(false)]
    public string Apellidos { get; set; } = null!;

    [StringLength(150)]
    [Unicode(false)]
    public string Correo { get; set; } = null!;

    [MaxLength(256)]
    public byte[] Contrasena { get; set; } = null!;

    [InverseProperty("IdUsuarioNavigation")]
    public virtual ICollection<Bitacora> Bitacoras { get; set; } = new List<Bitacora>();

    [InverseProperty("IdUsuarioNavigation")]
    public virtual Estudiante? Estudiante { get; set; }

    [ForeignKey("IdRol")]
    [InverseProperty("Usuarios")]
    public virtual Rol IdRolNavigation { get; set; } = null!;
}
