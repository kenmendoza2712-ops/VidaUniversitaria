using Microsoft.EntityFrameworkCore;
using Vidauniversitaria.Api.Data;
using Vidauniversitaria.Api.Services;
using NSwag.AspNetCore;
using Vidauniversitaria.Api.Data.Scaffold;

var builder = WebApplication.CreateBuilder(args);

// Habilita los controladores HTTP.
builder.Services.AddControllers();

// Genera el documento OpenAPI; más adelante añadiremos la interfaz visual Swagger.
builder.Services.AddOpenApi();

// Obtiene la conexión VidaU desde la configuración o los Secretos de usuario.
var connectionString = builder.Configuration.GetConnectionString("VidaU");

if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException(
        "No se encontró ConnectionStrings:VidaU. Revisa los Secretos de usuario.");
}

// Registra el contexto para que EF Core pueda conectarse a SQL Server.
builder.Services.AddDbContext<VidaUniversitariaScaffoldContext>(options =>
    options.UseSqlServer(connectionString));

// Crea una instancia del servicio por cada solicitud HTTP.
builder.Services.AddScoped<IUniversidadService, UniversidadService>();

var app = builder.Build();

// En desarrollo se publica el documento OpenAPI.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();

    app.UseSwaggerUi(options =>
    {
        options.DocumentPath = "/openapi/v1.json";
    });
}

app.UseHttpsRedirection();

// Los controladores que creemos se conectarán aquí.
app.MapControllers();

app.Run();