using Vidauniversitaria.Api.DTOs;

namespace Vidauniversitaria.Api.Services;

/// <summary>
/// Define las operaciones disponibles para consultar universidades.
/// </summary>
public interface IUniversidadService
{
    Task<List<UniversidadRespuestaDto>> ConsultarAsync(
        int? idUniversidad,
        CancellationToken cancellationToken);
}
