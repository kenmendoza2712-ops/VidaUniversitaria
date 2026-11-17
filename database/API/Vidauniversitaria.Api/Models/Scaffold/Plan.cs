using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Models.Scaffold;

[Table("Plan", Schema = "VidaU")]
public partial class Plan
{
    [Key]
    [Column("idPlan")]
    public int IdPlan { get; set; }

    [StringLength(100)]
    [Unicode(false)]
    public string Nombre { get; set; } = null!;

    [StringLength(300)]
    [Unicode(false)]
    public string? Descripcion { get; set; }

    [Column(TypeName = "decimal(10, 2)")]
    public decimal Monto { get; set; }

    [InverseProperty("IdPlanNavigation")]
    public virtual ICollection<Suscripcion> Suscripcions { get; set; } = new List<Suscripcion>();
}
