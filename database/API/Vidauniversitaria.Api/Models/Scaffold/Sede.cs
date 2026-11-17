using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Models.Scaffold;

[Table("Sede", Schema = "VidaU")]
public partial class Sede
{
    [Key]
    [Column("idSede")]
    public int IdSede { get; set; }

    [Column("idUniversidad")]
    public int IdUniversidad { get; set; }

    [StringLength(150)]
    [Unicode(false)]
    public string Nombre { get; set; } = null!;

    [StringLength(20)]
    [Unicode(false)]
    public string Estado { get; set; } = null!;

    [StringLength(250)]
    [Unicode(false)]
    public string? Direccion { get; set; }

    [ForeignKey("IdUniversidad")]
    [InverseProperty("Sedes")]
    public virtual Universidad IdUniversidadNavigation { get; set; } = null!;

    [ForeignKey("IdSede")]
    [InverseProperty("IdSedes")]
    public virtual ICollection<Carrera> IdCarreras { get; set; } = new List<Carrera>();
}
