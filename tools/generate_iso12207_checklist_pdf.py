from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    KeepTogether,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "pdf" / "lista_cotejo_codigo_iso_iec_ieee_12207_2026.pdf"

NAVY = colors.HexColor("#16324F")
BLUE = colors.HexColor("#2563A6")
PALE_BLUE = colors.HexColor("#EAF2F8")
PALE_GRAY = colors.HexColor("#F5F7F9")
MID_GRAY = colors.HexColor("#64748B")
LINE = colors.HexColor("#CAD3DD")
WHITE = colors.white


def register_fonts():
    font_dir = Path("C:/Windows/Fonts")
    regular = font_dir / "arial.ttf"
    bold = font_dir / "arialbd.ttf"
    if regular.exists() and bold.exists():
        pdfmetrics.registerFont(TTFont("Checklist", str(regular)))
        pdfmetrics.registerFont(TTFont("Checklist-Bold", str(bold)))
        return "Checklist", "Checklist-Bold"
    return "Helvetica", "Helvetica-Bold"


FONT, FONT_BOLD = register_fonts()

styles = getSampleStyleSheet()
styles.add(
    ParagraphStyle(
        name="TitleCustom",
        fontName=FONT_BOLD,
        fontSize=19,
        leading=23,
        textColor=NAVY,
        alignment=TA_LEFT,
        spaceAfter=2 * mm,
    )
)
styles.add(
    ParagraphStyle(
        name="SubtitleCustom",
        fontName=FONT,
        fontSize=9,
        leading=12,
        textColor=MID_GRAY,
        spaceAfter=4 * mm,
    )
)
styles.add(
    ParagraphStyle(
        name="SectionCustom",
        fontName=FONT_BOLD,
        fontSize=11,
        leading=14,
        textColor=NAVY,
        spaceBefore=1 * mm,
        spaceAfter=2 * mm,
    )
)
styles.add(
    ParagraphStyle(
        name="BodyCustom",
        fontName=FONT,
        fontSize=8.3,
        leading=11,
        textColor=colors.HexColor("#233142"),
    )
)
styles.add(
    ParagraphStyle(
        name="SmallCustom",
        fontName=FONT,
        fontSize=7.2,
        leading=9,
        textColor=MID_GRAY,
    )
)
styles.add(
    ParagraphStyle(
        name="QuestionCustom",
        fontName=FONT_BOLD,
        fontSize=8.1,
        leading=10.2,
        textColor=colors.HexColor("#172B3A"),
    )
)


ITEMS = [
    (
        "¿El repositorio contiene el código fuente completo y una estructura clara por módulos, capas o componentes?",
        "Árbol del repositorio; módulos identificables; README; exclusión de archivos generados.",
        "6.4.4-6.4.7",
    ),
    (
        "¿Las funciones implementadas en el código pueden relacionarse con requisitos, historias de usuario o criterios de aceptación?",
        "Enlaces requisito-tarea-commit; identificadores; matriz de trazabilidad; demostración funcional.",
        "6.4.2-6.4.3; 6.4.7",
    ),
    (
        "¿La arquitectura planteada se refleja realmente en el código y mantiene responsabilidades y dependencias bien separadas?",
        "Correspondencia diagrama-código; límites entre capas; dependencias justificadas; bajo acoplamiento.",
        "6.4.4; 6.4.7",
    ),
    (
        "¿Los modelos de datos, contratos de API e interfaces coinciden con su implementación y manejan correctamente sus restricciones?",
        "Esquemas; migraciones; validaciones; endpoints; serialización; compatibilidad entre componentes.",
        "6.4.5-6.4.8",
    ),
    (
        "¿El código sigue convenciones definidas de nombres, formato, estructura y documentación, sin duplicación innecesaria?",
        "Guía de estilo; formateador o linter; comentarios útiles; análisis de duplicación; revisión de muestra.",
        "6.4.7; 6.3.8",
    ),
    (
        "¿El desarrollo del código está controlado mediante versiones, ramas, commits comprensibles, revisiones y líneas base?",
        "Historial Git; estrategia de ramas; pull requests; revisiones; etiquetas o versiones liberadas.",
        "6.3.5; 6.4.7",
    ),
    (
        "¿Las bibliotecas y herramientas externas están declaradas, versionadas, justificadas y libres de vulnerabilidades críticas conocidas?",
        "Manifiesto y archivo de bloqueo; inventario; licencias; análisis de dependencias; actualizaciones controladas.",
        "6.3.4-6.3.5; 6.4.7",
    ),
    (
        "¿El código aplica controles de seguridad apropiados para autenticación, autorización, entradas, datos sensibles y secretos?",
        "Validación de entradas; permisos; almacenamiento seguro; secretos fuera del repositorio; análisis de seguridad.",
        "6.3.4; 6.4.5; 6.4.7",
    ),
    (
        "¿La implementación maneja errores, estados inesperados, concurrencia y fallos externos sin dejar el sistema inconsistente?",
        "Excepciones controladas; transacciones; reintentos; timeouts; mensajes seguros; pruebas de fallos.",
        "6.4.6-6.4.7; 6.4.9",
    ),
    (
        "¿Existen pruebas unitarias automatizadas para la lógica relevante, incluidos casos normales, límites y errores?",
        "Suite ejecutable; aserciones; dobles de prueba; casos límite; reporte de resultados o cobertura.",
        "6.4.9; 6.3.8",
    ),
    (
        "¿Existen pruebas de integración para las interacciones entre módulos, API, base de datos y servicios externos?",
        "Pruebas de contratos; integración con base de datos; dobles de servicios; resultados reproducibles.",
        "6.4.8-6.4.9",
    ),
    (
        "¿La construcción automática ejecuta compilación, análisis estático y pruebas, y bloquea cambios cuando falla un control esencial?",
        "Pipeline de CI; registros de ejecución; reglas de calidad; estados de compilación y pruebas.",
        "6.4.7-6.4.9; 6.3.8",
    ),
    (
        "¿Los defectos encontrados se registran, se corrigen con cambios rastreables y cuentan con pruebas de regresión?",
        "Incidencias; commits asociados; revisión de la corrección; prueba que reproduce y evita la regresión.",
        "6.3.2; 6.3.5; 6.4.9",
    ),
    (
        "¿El sistema puede construirse, configurarse y desplegarse de forma reproducible en un ambiente limpio?",
        "Instrucciones verificables; variables de entorno; contenedores o scripts; migraciones; versión del artefacto.",
        "6.4.7-6.4.8; 6.4.10",
    ),
    (
        "¿El código es mantenible y observable, con registros útiles, documentación técnica y facilidad para modificarlo sin romper funciones existentes?",
        "Logs sin datos sensibles; documentación de módulos; deuda técnica; refactorizaciones; pruebas de regresión.",
        "6.4.12-6.4.13; 6.3.6",
    ),
]


def footer(canvas, doc):
    canvas.saveState()
    width, _ = A4
    canvas.setStrokeColor(LINE)
    canvas.setLineWidth(0.5)
    canvas.line(16 * mm, 13 * mm, width - 16 * mm, 13 * mm)
    canvas.setFont(FONT, 7)
    canvas.setFillColor(MID_GRAY)
    canvas.drawString(16 * mm, 8.5 * mm, "Evaluación técnica del código - ISO/IEC/IEEE 12207:2026")
    canvas.drawRightString(width - 16 * mm, 8.5 * mm, f"Página {doc.page}")
    canvas.restoreState()


def metadata_table():
    data = [
        ["Proyecto evaluado:", "", "Fecha:", ""],
        ["Equipo:", "", "Evaluador(a):", ""],
    ]
    table = Table(data, colWidths=[30 * mm, 68 * mm, 27 * mm, 48 * mm], rowHeights=[10 * mm, 10 * mm])
    table.setStyle(
        TableStyle(
            [
                ("FONTNAME", (0, 0), (-1, -1), FONT),
                ("FONTNAME", (0, 0), (0, -1), FONT_BOLD),
                ("FONTNAME", (2, 0), (2, -1), FONT_BOLD),
                ("FONTSIZE", (0, 0), (-1, -1), 8),
                ("TEXTCOLOR", (0, 0), (-1, -1), colors.HexColor("#233142")),
                ("BACKGROUND", (0, 0), (0, -1), PALE_BLUE),
                ("BACKGROUND", (2, 0), (2, -1), PALE_BLUE),
                ("BOX", (0, 0), (-1, -1), 0.6, LINE),
                ("INNERGRID", (0, 0), (-1, -1), 0.4, LINE),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    return table


def scale_table():
    cells = [
        [Paragraph("<b>Sí - 1 punto</b><br/>Completo, vigente y demostrado.", styles["SmallCustom"]),
         Paragraph("<b>Parcial - 0.5</b><br/>Existe, pero incompleto o desactualizado.", styles["SmallCustom"]),
         Paragraph("<b>No - 0 puntos</b><br/>No existe o no se demuestra.", styles["SmallCustom"]),
         Paragraph("<b>N/A</b><br/>No aplica y el equipo lo justifica.", styles["SmallCustom"])],
    ]
    table = Table(cells, colWidths=[43.25 * mm] * 4)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), PALE_GRAY),
                ("BOX", (0, 0), (-1, -1), 0.5, LINE),
                ("INNERGRID", (0, 0), (-1, -1), 0.5, LINE),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    return table


def checklist_table(start, end):
    header = [
        Paragraph("N.º", styles["QuestionCustom"]),
        Paragraph("Criterio de evaluación", styles["QuestionCustom"]),
        Paragraph("Evidencia esperada", styles["QuestionCustom"]),
        Paragraph("Resultado", styles["QuestionCustom"]),
    ]
    rows = [header]
    for index in range(start, end):
        question, evidence, clause = ITEMS[index]
        result = "[ ] Sí<br/>[ ] Parcial<br/>[ ] No<br/>[ ] N/A"
        rows.append(
            [
                Paragraph(str(index + 1), styles["QuestionCustom"]),
                Paragraph(question, styles["BodyCustom"]),
                Paragraph(f"{evidence}<br/><font color='#64748B'>Referencia: {clause}</font>", styles["SmallCustom"]),
                Paragraph(result, styles["SmallCustom"]),
            ]
        )
    table = Table(rows, colWidths=[9 * mm, 81 * mm, 58 * mm, 25 * mm], repeatRows=1)
    style = [
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
        ("FONTNAME", (0, 0), (-1, 0), FONT_BOLD),
        ("ALIGN", (0, 0), (0, -1), "CENTER"),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("BOX", (0, 0), (-1, -1), 0.65, LINE),
        ("INNERGRID", (0, 0), (-1, -1), 0.4, LINE),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]
    for row in range(1, len(rows)):
        if row % 2 == 0:
            style.append(("BACKGROUND", (0, row), (-1, row), PALE_GRAY))
    table.setStyle(TableStyle(style))
    return table


def observations_box(label="Observaciones del evaluador"):
    table = Table(
        [[Paragraph(label, styles["QuestionCustom"])], [""]],
        colWidths=[173 * mm],
        rowHeights=[7 * mm, 25 * mm],
    )
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), PALE_BLUE),
                ("BOX", (0, 0), (-1, -1), 0.6, LINE),
                ("INNERGRID", (0, 0), (-1, -1), 0.4, LINE),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ]
        )
    )
    return table


def build_pdf():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    doc = BaseDocTemplate(
        str(OUTPUT),
        pagesize=A4,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        topMargin=16 * mm,
        bottomMargin=18 * mm,
        title="Lista de cotejo del código - ISO/IEC/IEEE 12207:2026",
        author="Material de evaluación académica",
        subject="Evaluación del código y desarrollo técnico conforme al marco de procesos del ciclo de vida",
    )
    frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="main")
    doc.addPageTemplates([PageTemplate(id="checklist", frames=[frame], onPage=footer)])

    story = [
        Paragraph("Lista de cotejo del código", styles["TitleCustom"]),
        Paragraph("Evaluación del desarrollo técnico de una app o sistema basada en ISO/IEC/IEEE 12207:2026", styles["SubtitleCustom"]),
        metadata_table(),
        Spacer(1, 4 * mm),
        Paragraph("Instrucciones de aplicación", styles["SectionCustom"]),
        Paragraph(
            "Revise el repositorio y solicite que el equipo ejecute el sistema, la construcción y las pruebas. Califique únicamente la implementación y sus evidencias técnicas. Una explicación oral o un documento de diseño que no coincida con el código no debe considerarse cumplimiento completo.",
            styles["BodyCustom"],
        ),
        Spacer(1, 3 * mm),
        scale_table(),
        Spacer(1, 4 * mm),
        checklist_table(0, 5),
        PageBreak(),
        Paragraph("Código, dependencias y seguridad", styles["SectionCustom"]),
        checklist_table(5, 10),
        Spacer(1, 5 * mm),
        observations_box("Observaciones parciales"),
        PageBreak(),
        Paragraph("Pruebas, integración y mantenibilidad", styles["SectionCustom"]),
        checklist_table(10, 15),
        Spacer(1, 4 * mm),
    ]

    scoring = Table(
        [
            [Paragraph("Puntaje obtenido", styles["QuestionCustom"]), "_______ / 15", Paragraph("Elementos N/A", styles["QuestionCustom"]), "_______"],
            [Paragraph("Resultado orientativo", styles["QuestionCustom"]), Paragraph("13-15: sólido | 10-12.5: adecuado | 7-9.5: parcial | 0-6.5: insuficiente", styles["BodyCustom"]), "", ""],
        ],
        colWidths=[38 * mm, 62 * mm, 38 * mm, 35 * mm],
    )
    scoring.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (0, -1), PALE_BLUE),
                ("BACKGROUND", (2, 0), (2, 0), PALE_BLUE),
                ("SPAN", (1, 1), (3, 1)),
                ("BOX", (0, 0), (-1, -1), 0.65, LINE),
                ("INNERGRID", (0, 0), (-1, -1), 0.4, LINE),
                ("FONTNAME", (0, 0), (-1, -1), FONT),
                ("FONTSIZE", (0, 0), (-1, -1), 8),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    story.extend(
        [
            scoring,
            Spacer(1, 4 * mm),
            observations_box("Conclusiones y recomendaciones"),
            Spacer(1, 3 * mm),
            KeepTogether(
                [
                    Paragraph("Nota de uso", styles["SectionCustom"]),
                    Paragraph(
                        "Instrumento académico enfocado exclusivamente en el código y en las evidencias técnicas del desarrollo. No evalúa de forma completa todos los procesos de la norma ni constituye una auditoría o certificación de conformidad.",
                        styles["SmallCustom"],
                    ),
                    Spacer(1, 1.5 * mm),
                    Paragraph(
                        "Fuentes: ISO, ficha oficial de ISO/IEC/IEEE 12207:2026 (https://www.iso.org/standard/90219.html) e índice público de la segunda edición, abril de 2026.",
                        styles["SmallCustom"],
                    ),
                ]
            ),
        ]
    )

    doc.build(story)
    print(OUTPUT)


if __name__ == "__main__":
    build_pdf()
