using System.Data;
using Microsoft.Data.SqlClient;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var connectionString = builder.Configuration.GetConnectionString("VidaU");

if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException(
        "No se encontró ConnectionStrings:VidaU en los secretos de usuario.");
}

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();
app.UseAuthorization();

app.MapGet("/api/universidades", async (CancellationToken cancellationToken) =>
{
    await using var connection = new SqlConnection(connectionString);

    await using var command = new SqlCommand(
        "VidaU.sp_Universidad_Consultar",
        connection)
    {
        CommandType = CommandType.StoredProcedure
    };

    command.Parameters.Add("@idUniversidad", SqlDbType.Int).Value = DBNull.Value;

    await connection.OpenAsync(cancellationToken);

    await using var reader = await command.ExecuteReaderAsync(cancellationToken);

    var universidades = new List<object>();

    while (await reader.ReadAsync(cancellationToken))
    {
        var ordinalTelefono = reader.GetOrdinal("Telefono");

        universidades.Add(new
        {
            idUniversidad = reader.GetInt32(reader.GetOrdinal("idUniversidad")),
            nombre = reader.GetString(reader.GetOrdinal("Nombre")),
            correo = reader.GetString(reader.GetOrdinal("Correo")),
            estado = reader.GetString(reader.GetOrdinal("Estado")),
            telefono = reader.IsDBNull(ordinalTelefono)
                ? null
                : reader.GetString(ordinalTelefono)
        });
    }

    return Results.Ok(universidades);
});

app.MapControllers();

app.Run();