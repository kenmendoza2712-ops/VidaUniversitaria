using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Models.Scaffold;

[Table("Bitacora", Schema = "VidaU")]
public partial class Bitacora
{
    [Key]
    [Column("idBitacora")]
    public int IdBitacora { get; set; }

    [Column("idUsuario")]
    public int IdUsuario { get; set; }

    [StringLength(100)]
    [Unicode(false)]
    public string Accion { get; set; } = null!;

    [StringLength(100)]
    [Unicode(false)]
    public string TablaAfectada { get; set; } = null!;

    [Column(TypeName = "datetime")]
    public DateTime FechaHora { get; set; }

    [StringLength(500)]
    [Unicode(false)]
    public string? Descripcion { get; set; }

    [ForeignKey("IdUsuario")]
    [InverseProperty("Bitacoras")]
    public virtual Usuario IdUsuarioNavigation { get; set; } = null!;
}
