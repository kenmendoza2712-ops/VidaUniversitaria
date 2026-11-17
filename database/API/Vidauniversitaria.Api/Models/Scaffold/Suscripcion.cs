using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Models.Scaffold;

[Table("Suscripcion", Schema = "VidaU")]
public partial class Suscripcion
{
    [Key]
    [Column("idSuscripcion")]
    public int IdSuscripcion { get; set; }

    [Column("idUniversidad")]
    public int IdUniversidad { get; set; }

    [Column("idPlan")]
    public int IdPlan { get; set; }

    [StringLength(20)]
    [Unicode(false)]
    public string Estado { get; set; } = null!;

    public DateOnly FechaInicio { get; set; }

    public DateOnly? FechaFin { get; set; }

    [ForeignKey("IdPlan")]
    [InverseProperty("Suscripcions")]
    public virtual Plan IdPlanNavigation { get; set; } = null!;

    [ForeignKey("IdUniversidad")]
    [InverseProperty("Suscripcions")]
    public virtual Universidad IdUniversidadNavigation { get; set; } = null!;
}
