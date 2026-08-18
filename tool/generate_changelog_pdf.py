"""Generate FitForge changelog PDF for recent commits."""
from __future__ import annotations

from datetime import datetime
from pathlib import Path

from fpdf import FPDF

OUTPUT = Path(r"C:\Users\xemil\OneDrive\Escritorio\FitForge_changelog_ultimos_3_commits.pdf")
FONT_REGULAR = Path(r"C:\Windows\Fonts\arial.ttf")
FONT_BOLD = Path(r"C:\Windows\Fonts\arialbd.ttf")


class ChangelogPDF(FPDF):
    def __init__(self) -> None:
        super().__init__()
        self.set_margins(20, 20, 20)
        self.set_auto_page_break(auto=True, margin=20)
        self.add_font("Arial", "", str(FONT_REGULAR))
        self.add_font("Arial", "B", str(FONT_BOLD))

    def _reset_x(self) -> None:
        self.set_x(self.l_margin)

    def write_line(self, text: str, *, size: int = 10, bold: bool = False, color: tuple[int, int, int] = (40, 40, 40), spacing: float = 6) -> None:
        self._reset_x()
        self.set_font("Arial", "B" if bold else "", size)
        self.set_text_color(*color)
        self.multi_cell(self.epw, spacing, text)
        self._reset_x()

    def section_title(self, text: str) -> None:
        self.ln(4)
        self.write_line(text, size=13, bold=True, color=(30, 30, 30), spacing=8)

    def subsection_title(self, text: str) -> None:
        self.ln(2)
        self.write_line(text, size=11, bold=True, color=(50, 50, 50), spacing=7)

    def bullet(self, text: str) -> None:
        self.write_line(f"• {text}", size=10, spacing=6)


def build_pdf() -> None:
    pdf = ChangelogPDF()
    pdf.add_page()

    pdf.write_line("FitForge — Novedades recientes", size=20, bold=True, color=(20, 20, 20), spacing=10)
    pdf.write_line(
        f"Últimos 3 commits en main · Generado el {datetime.now().strftime('%d/%m/%Y %H:%M')}",
        size=10,
        color=(90, 90, 90),
        spacing=7,
    )
    pdf.ln(4)

    pdf.section_title("1. Etiqueta de plan en perfil")
    pdf.bullet("Muestra Gymrat o Gymrat Pro debajo del nombre en tu perfil.")
    pdf.bullet("Lo mismo visible cuando un amigo ve tu perfil.")
    pdf.bullet("Usuarios Free no ven etiqueta.")
    pdf.write_line(
        "Commit: 38f2ccf — Show Gymrat plan badge below profile names.",
        size=9,
        color=(110, 110, 110),
        spacing=5,
    )

    pdf.section_title("2. Feed social, suscripciones y coach")

    pdf.subsection_title("Feed social")
    pdf.bullet("Nueva pestaña Feed en Social.")
    pdf.bullet("Publicaciones automáticas: entrenos completados, medallas y subidas de nivel.")
    pdf.bullet("PRs opt-in al cerrar el resumen del entreno (checkboxes).")
    pdf.bullet("Ves tus propias publicaciones en el feed.")
    pdf.bullet("TTL de 24 h en publicaciones (limpieza automática en base de datos).")
    pdf.bullet("Reacciones con emoji (long press): fuerza, fuego, aplausos, trofeo y corazon.")
    pdf.bullet("Sin snackbars intrusivos para eventos del feed.")

    pdf.subsection_title("Planes y límites (Free / Gymrat / Gymrat Pro)")
    pdf.bullet("Campo subscription_tier en perfiles.")
    pdf.bullet("Límite de rutinas guardadas: Free 10, Gymrat 20, Pro 50.")
    pdf.bullet("Límite diario de Coach IA: Free 10, Gymrat 30, Pro ilimitado.")
    pdf.bullet("Features por plan: IA proactiva, modo entrenador, color de acento, foto de comida con IA, etc.")

    pdf.subsection_title("Coach IA y nutrición")
    pdf.bullet("Contexto nutricional para el coach (macros, calorías, etc.).")
    pdf.bullet("Control de uso diario del coach.")
    pdf.bullet("Bloqueo/UI cuando se alcanza el límite diario.")

    pdf.subsection_title("Perfil y onboarding")
    pdf.bullet("Onboarding obligatorio de perfil (peso, altura, edad, etc.).")
    pdf.bullet("Diálogo de actualización de peso.")
    pdf.bullet("Gate que redirige si el perfil está incompleto.")

    pdf.subsection_title("Entrenos, rutinas y assets")
    pdf.bullet("Mejoras en resumen de entreno (publicación de PRs al cerrar).")
    pdf.bullet("Validación de límite de rutinas al crear, editar, compartir y con IA.")
    pdf.bullet("Conversión masiva de ejercicios GIF → WebP (app más liviana).")
    pdf.bullet("Migraciones Supabase 032–040 (feed, PRs, TTL, rutinas, reacciones).")

    pdf.ln(2)
    pdf.write_line(
        "Commit: c510548 — Add social feed, subscription tiers, and coach onboarding improvements.",
        size=9,
        color=(110, 110, 110),
        spacing=5,
    )

    pdf.section_title("3. Mejoras iOS (merge remoto)")
    pdf.bullet("Deployment target iOS 15 + integración CocoaPods.")
    pdf.bullet("Corrección al compartir resumen de entreno en iOS.")
    pdf.bullet("Mejores etiquetas en el share sheet de iOS.")
    pdf.bullet("Ajustes en workout_summary_screen traídos del remoto.")
    pdf.write_line("Commit: 3de9382 — Merge branch 'main'", size=9, color=(110, 110, 110), spacing=5)

    pdf.ln(6)
    pdf.write_line(
        "Nota: el commit de colores de acento personalizables (c9e525b) es el cuarto en el historial, "
        "justo antes del merge; no entra en estos 3 commits, aunque sí está en main.",
        size=9,
        color=(120, 120, 120),
        spacing=5,
    )

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    pdf.output(str(OUTPUT))
    print(OUTPUT)


if __name__ == "__main__":
    build_pdf()
