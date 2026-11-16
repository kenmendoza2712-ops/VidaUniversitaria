using Microsoft.EntityFrameworkCore;

namespace Vidauniversitaria.Api.Data;

/// <summary>
/// Contexto de Entity Framework Core para acceder a SQL Server.
/// En esta primera etapa se usará para ejecutar procedimientos almacenados.
/// </summary>
public class VidaUniversitariaDbContext : DbContext
{
    public VidaUniversitariaDbContext(
        DbContextOptions<VidaUniversitariaDbContext> options)
        : base(options)
    {
    }
}