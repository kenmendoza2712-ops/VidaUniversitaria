using Microsoft.AspNetCore.Mvc;
using Vidauniversitaria.Api.Services;

namespace Vidauniversitaria.Api.Controllers;

/// <summary>
/// Expone las operaciones HTTP para consultar universidades.
/// </summary>
[ApiController]
[Route("api/universidades")]
public sealed class UniversidadesController : ControllerBase
{
    private readonly IUniversidadService _universidadService;

    public UniversidadesController(IUniversidadService universidadService)
    {
        _universidadService = universidadService;
    }

    /// <summary>
    /// Devuelve todas las universidades o una por identificador.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> Consultar(
        [FromQuery] int? idUniversidad,
        CancellationToken cancellationToken)
    {
        var universidades = await _universidadService.ConsultarAsync(
            idUniversidad,
            cancellationToken);

        return Ok(universidades);
    }
}