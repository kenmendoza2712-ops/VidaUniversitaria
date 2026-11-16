using System.ComponentModel.DataAnnotations.Schema;

namespace Vidauniversitaria.Api.DTOs;

/// <summary>
/// Representa una fila devuelta por VidaU.sp_Universidad_Consultar.
/// </summary>
public sealed class UniversidadRespuestaDto
{
    [Column("idUniversidad")]
    public int IdUniversidad { get; set; }

    public string Nombre { get; set; } = string.Empty;
    public string Correo { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
    public string? Telefono { get; set; }
}