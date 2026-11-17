using Microsoft.EntityFrameworkCore;
using Vidauniversitaria.Api.Data.Scaffold;
using Vidauniversitaria.Api.DTOs;

namespace Vidauniversitaria.Api.Services;

/// <summary>
/// Ejecuta las consultas de universidades mediante procedimientos almacenados.
/// </summary>
public sealed class UniversidadService : IUniversidadService
{
    private readonly VidaUniversitariaScaffoldContext _context;

    public UniversidadService(VidaUniversitariaScaffoldContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Consulta todas las universidades o una universidad por su identificador.
    /// </summary>
    public async Task<List<UniversidadRespuestaDto>> ConsultarAsync(
        int? idUniversidad,
        CancellationToken cancellationToken)
    {
        return await _context.Database
            .SqlQuery<UniversidadRespuestaDto>(
                $"EXEC VidaU.sp_Universidad_Consultar @idUniversidad = {idUniversidad}")
            .ToListAsync(cancellationToken);
    }
}
