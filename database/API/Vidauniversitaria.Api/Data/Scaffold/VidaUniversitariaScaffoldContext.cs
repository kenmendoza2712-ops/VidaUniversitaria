using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using Vidauniversitaria.Api.Models.Scaffold;

namespace Vidauniversitaria.Api.Data.Scaffold;

public partial class VidaUniversitariaScaffoldContext : DbContext
{
    public VidaUniversitariaScaffoldContext(DbContextOptions<VidaUniversitariaScaffoldContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Bitacora> Bitacoras { get; set; }

    public virtual DbSet<Carrera> Carreras { get; set; }

    public virtual DbSet<Curso> Cursos { get; set; }

    public virtual DbSet<Estudiante> Estudiantes { get; set; }

    public virtual DbSet<Evaluacion> Evaluacions { get; set; }

    public virtual DbSet<Leccion> Leccions { get; set; }

    public virtual DbSet<Matricula> Matriculas { get; set; }

    public virtual DbSet<Plan> Plans { get; set; }

    public virtual DbSet<Profesor> Profesors { get; set; }

    public virtual DbSet<Resennium> Resennia { get; set; }

    public virtual DbSet<Rol> Rols { get; set; }

    public virtual DbSet<Sede> Sedes { get; set; }

    public virtual DbSet<Suscripcion> Suscripcions { get; set; }

    public virtual DbSet<Universidad> Universidads { get; set; }

    public virtual DbSet<Usuario> Usuarios { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Bitacora>(entity =>
        {
            entity.Property(e => e.FechaHora).HasDefaultValueSql("(getdate())", "DF_Bitacora_FechaHora");

            entity.HasOne(d => d.IdUsuarioNavigation).WithMany(p => p.Bitacoras)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Bitacora_Usuario");
        });

        modelBuilder.Entity<Carrera>(entity =>
        {
            entity.HasMany(d => d.IdCursos).WithMany(p => p.IdCarreras)
                .UsingEntity<Dictionary<string, object>>(
                    "CarreraCurso",
                    r => r.HasOne<Curso>().WithMany()
                        .HasForeignKey("IdCurso")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK_CarrCurso_Curso"),
                    l => l.HasOne<Carrera>().WithMany()
                        .HasForeignKey("IdCarrera")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK_CarrCurso_Carrera"),
                    j =>
                    {
                        j.HasKey("IdCarrera", "IdCurso");
                        j.ToTable("Carrera_Curso", "VidaU");
                        j.IndexerProperty<int>("IdCarrera").HasColumnName("idCarrera");
                        j.IndexerProperty<int>("IdCurso").HasColumnName("idCurso");
                    });

            entity.HasMany(d => d.IdEstudiantes).WithMany(p => p.IdCarreras)
                .UsingEntity<Dictionary<string, object>>(
                    "CarreraEstudiante",
                    r => r.HasOne<Estudiante>().WithMany()
                        .HasForeignKey("IdEstudiante")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK_CarrEst_Estudiante"),
                    l => l.HasOne<Carrera>().WithMany()
                        .HasForeignKey("IdCarrera")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK_CarrEst_Carrera"),
                    j =>
                    {
                        j.HasKey("IdCarrera", "IdEstudiante");
                        j.ToTable("Carrera_Estudiante", "VidaU");
                        j.IndexerProperty<int>("IdCarrera").HasColumnName("idCarrera");
                        j.IndexerProperty<int>("IdEstudiante").HasColumnName("idEstudiante");
                    });
        });

        modelBuilder.Entity<Estudiante>(entity =>
        {
            entity.HasOne(d => d.IdUsuarioNavigation).WithOne(p => p.Estudiante)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Estudiante_Usuario");
        });

        modelBuilder.Entity<Evaluacion>(entity =>
        {
            entity.HasOne(d => d.IdResenniaNavigation).WithMany(p => p.Evaluacions)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Evaluacion_Resennia");
        });

        modelBuilder.Entity<Leccion>(entity =>
        {
            entity.HasOne(d => d.IdCursoNavigation).WithMany(p => p.Leccions)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Leccion_Curso");

            entity.HasOne(d => d.IdProfesorNavigation).WithMany(p => p.Leccions)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Leccion_Profesor");
        });

        modelBuilder.Entity<Matricula>(entity =>
        {
            entity.Property(e => e.Estado).HasDefaultValue("Matriculado", "DF_Matricula_Estado");
            entity.Property(e => e.FechaMatricula).HasDefaultValueSql("(CONVERT([date],getdate()))", "DF_Matricula_Fecha");

            entity.HasOne(d => d.IdEstudianteNavigation).WithMany(p => p.Matriculas)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Matricula_Estudiante");
        });

        modelBuilder.Entity<Resennium>(entity =>
        {
            entity.ToTable("Resennia", "VidaU", tb => tb.HasTrigger("trg_Resennia_AuditarEstado"));

            entity.Property(e => e.EsAnonima).HasDefaultValue(true, "DF_Resennia_EsAnonima");
            entity.Property(e => e.Estado).HasDefaultValue("EnRevision", "DF_Resennia_Estado");
            entity.Property(e => e.FechaResennia).HasDefaultValueSql("(getdate())", "DF_Resennia_Fecha");

            entity.HasOne(d => d.IdEstudianteNavigation).WithMany(p => p.Resennia)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Resennia_Estudiante");

            entity.HasOne(d => d.IdLeccionNavigation).WithMany(p => p.Resennia)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Resennia_Leccion");
        });

        modelBuilder.Entity<Sede>(entity =>
        {
            entity.Property(e => e.Estado).HasDefaultValue("Activa", "DF_Sede_Estado");

            entity.HasOne(d => d.IdUniversidadNavigation).WithMany(p => p.Sedes)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Sede_Universidad");

            entity.HasMany(d => d.IdCarreras).WithMany(p => p.IdSedes)
                .UsingEntity<Dictionary<string, object>>(
                    "SedeCarrera",
                    r => r.HasOne<Carrera>().WithMany()
                        .HasForeignKey("IdCarrera")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK_SedeCarr_Carrera"),
                    l => l.HasOne<Sede>().WithMany()
                        .HasForeignKey("IdSede")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK_SedeCarr_Sede"),
                    j =>
                    {
                        j.HasKey("IdSede", "IdCarrera");
                        j.ToTable("Sede_Carrera", "VidaU");
                        j.IndexerProperty<int>("IdSede").HasColumnName("idSede");
                        j.IndexerProperty<int>("IdCarrera").HasColumnName("idCarrera");
                    });
        });

        modelBuilder.Entity<Suscripcion>(entity =>
        {
            entity.ToTable("Suscripcion", "VidaU", tb => tb.HasTrigger("trg_Suscripcion_ValidarTraslape"));

            entity.Property(e => e.Estado).HasDefaultValue("Activa", "DF_Suscripcion_Estado");

            entity.HasOne(d => d.IdPlanNavigation).WithMany(p => p.Suscripcions)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Suscripcion_Plan");

            entity.HasOne(d => d.IdUniversidadNavigation).WithMany(p => p.Suscripcions)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Suscripcion_Universidad");
        });

        modelBuilder.Entity<Universidad>(entity =>
        {
            entity.Property(e => e.Estado).HasDefaultValue("Activa", "DF_Universidad_Estado");

            entity.HasMany(d => d.IdProfesors).WithMany(p => p.IdUniversidads)
                .UsingEntity<Dictionary<string, object>>(
                    "UniversidadProfesor",
                    r => r.HasOne<Profesor>().WithMany()
                        .HasForeignKey("IdProfesor")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK_UnivProf_Profesor"),
                    l => l.HasOne<Universidad>().WithMany()
                        .HasForeignKey("IdUniversidad")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK_UnivProf_Universidad"),
                    j =>
                    {
                        j.HasKey("IdUniversidad", "IdProfesor");
                        j.ToTable("Universidad_Profesor", "VidaU");
                        j.IndexerProperty<int>("IdUniversidad").HasColumnName("idUniversidad");
                        j.IndexerProperty<int>("IdProfesor").HasColumnName("idProfesor");
                    });
        });

        modelBuilder.Entity<Usuario>(entity =>
        {
            entity.HasOne(d => d.IdRolNavigation).WithMany(p => p.Usuarios)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Usuario_Rol");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
