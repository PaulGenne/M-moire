#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
==============================================================================
Générateur Python du Document Word des Résultats du Mémoire (UMons)
Auteur : Analyse de données & Mémoire de Fin d'Études : Paul Genné
Promoteur : Denis Michez | Co-promotrice : Sarah Lescot

Mise en page en double page (vis-à-vis / pages en regard) :
- Page de GAUCHE (pages paires) : Tableaux et Graphiques (données visuelles)
- Page de DROITE (pages impaires) : Description factuelle et rigoureuse des résultats
Exclusions strictes appliquées :
- Suppression totale du point 1 (échantillonnage et audit initial)
- Suppression du premier tableau du point 3 (tableau initial des 27 genres)
Approche rédactionnelle :
- Style académique élégant du mémoire, purement descriptif des résultats (sans interprétations)
==============================================================================
"""

import os
import sys
from docx import Document
from docx.shared import Inches, Pt, RGBColor, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

# --- Couleurs de la charte éditoriale (AGENTS.md) ---
COLOR_NAVY_HEX = "1B365D"       # Bleu nuit (Titres majeurs, en-têtes)
COLOR_SLATE_HEX = "4A90E2"      # Bleu ardoise
COLOR_LIGHT_BG_HEX = "F4F6F8"   # Fond zébré doux
COLOR_BORDER_HEX = "D0D7DE"     # Bordures subtiles
COLOR_WHITE_HEX = "FFFFFF"

COLOR_NAVY_RGB = RGBColor(27, 54, 93)
COLOR_GREY_RGB = RGBColor(85, 95, 110)
COLOR_BLACK_RGB = RGBColor(30, 30, 30)
COLOR_DARK_BLUE_RGB = RGBColor(33, 70, 120)


def configure_page_margins(doc):
    """Marges A4 optimisées de 2,0 cm pour garantir la tenue sur une page par volet."""
    for section in doc.sections:
        section.top_margin = Cm(2.0)
        section.bottom_margin = Cm(2.0)
        section.left_margin = Cm(2.0)
        section.right_margin = Cm(2.0)
        section.page_width = Cm(21.0)
        section.page_height = Cm(29.7)


def set_cell_background(cell, hex_color):
    """Applique une couleur d'arrière-plan à une cellule."""
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    tcPr.append(shd)


def set_cell_margins(cell, top=70, bottom=70, left=100, right=100):
    """Définit le padding interne (marges) d'une cellule en twips (dxa)."""
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(
        f'<w:tcMar {nsdecls("w")}>'
        f'<w:top w:w="{top}" w:type="dxa"/>'
        f'<w:bottom w:w="{bottom}" w:type="dxa"/>'
        f'<w:left w:w="{left}" w:type="dxa"/>'
        f'<w:right w:w="{right}" w:type="dxa"/>'
        f'</w:tcMar>'
    )
    tcPr.append(tcMar)


def set_table_styling(table, col_widths, border_color=COLOR_BORDER_HEX):
    """Applique des bordures horizontales douces, des largeurs strictes et l'interdiction de coupure."""
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False

    tblPr = table._tbl.tblPr
    borders = parse_xml(
        f'<w:tblBorders {nsdecls("w")}>'
        f'<w:top w:val="single" w:sz="6" w:space="0" w:color="{COLOR_NAVY_HEX}"/>'
        f'<w:bottom w:val="single" w:sz="6" w:space="0" w:color="{COLOR_NAVY_HEX}"/>'
        f'<w:insideH w:val="single" w:sz="4" w:space="0" w:color="{border_color}"/>'
        f'<w:insideV w:val="none"/>'
        f'<w:left w:val="none"/>'
        f'<w:right w:val="none"/>'
        f'</w:tblBorders>'
    )
    tblPr.append(borders)

    header_trPr = table.rows[0]._tr.get_or_add_trPr()
    header_trPr.append(parse_xml(f'<w:tblHeader {nsdecls("w")}/>'))

    for row in table.rows:
        trPr = row._tr.get_or_add_trPr()
        trPr.append(parse_xml(f'<w:cantSplit {nsdecls("w")}/>'))
        for idx, width in enumerate(col_widths):
            row.cells[idx].width = width


def add_custom_heading(doc, text, level):
    """Ajoute un titre hiérarchisé élégant respectant la charte."""
    p = doc.add_paragraph()
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.bold = True
    run.font.name = "Calibri"

    if level == 1:
        p.paragraph_format.space_before = Pt(14)
        p.paragraph_format.space_after = Pt(4)
        run.font.size = Pt(15)
        run.font.color.rgb = COLOR_NAVY_RGB
    elif level == 2:
        p.paragraph_format.space_before = Pt(10)
        p.paragraph_format.space_after = Pt(3)
        run.font.size = Pt(12.5)
        run.font.color.rgb = COLOR_NAVY_RGB
    elif level == 3:
        p.paragraph_format.space_before = Pt(8)
        p.paragraph_format.space_after = Pt(2)
        run.font.size = Pt(11)
        run.font.color.rgb = RGBColor(41, 128, 185)


def add_table_component(doc, table_num, title, description, headers, data_rows, col_widths, alignments=None):
    """Insère un tableau compact et accompagné de sa description descriptive."""
    if alignments is None:
        alignments = [WD_ALIGN_PARAGRAPH.LEFT] * len(headers)

    p_title = doc.add_paragraph()
    p_title.paragraph_format.space_before = Pt(6)
    p_title.paragraph_format.space_after = Pt(1)
    p_title.paragraph_format.keep_with_next = True
    
    r_tag = p_title.add_run(f"Tableau {table_num} : ")
    r_tag.bold = True
    r_tag.font.name = "Calibri"
    r_tag.font.size = Pt(9.5)
    r_tag.font.color.rgb = COLOR_NAVY_RGB

    r_tit = p_title.add_run(title)
    r_tit.bold = True
    r_tit.font.name = "Calibri"
    r_tit.font.size = Pt(9.5)
    r_tit.font.color.rgb = COLOR_BLACK_RGB

    if description:
        p_desc = doc.add_paragraph()
        p_desc.paragraph_format.space_before = Pt(0)
        p_desc.paragraph_format.space_after = Pt(4)
        p_desc.paragraph_format.keep_with_next = True
        r_desc = p_desc.add_run(description)
        r_desc.italic = True
        r_desc.font.name = "Calibri"
        r_desc.font.size = Pt(8.5)
        r_desc.font.color.rgb = COLOR_GREY_RGB

    table = doc.add_table(rows=len(data_rows) + 1, cols=len(headers))
    set_table_styling(table, col_widths)

    hdr_cells = table.rows[0].cells
    for i, h_text in enumerate(headers):
        cell = hdr_cells[i]
        cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        set_cell_background(cell, COLOR_NAVY_HEX)
        set_cell_margins(cell, top=80, bottom=80, left=90, right=90)
        p = cell.paragraphs[0]
        p.alignment = alignments[i]
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        p.paragraph_format.line_spacing = 1.0
        run = p.add_run(h_text)
        run.bold = True
        run.font.name = "Calibri"
        run.font.size = Pt(8.5)
        run.font.color.rgb = RGBColor(255, 255, 255)

    for r_idx, row_data in enumerate(data_rows):
        row_cells = table.rows[r_idx + 1].cells
        bg_col = COLOR_LIGHT_BG_HEX if (r_idx % 2 == 1) else COLOR_WHITE_HEX
        for c_idx, cell_value in enumerate(row_data):
            cell = row_cells[c_idx]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            set_cell_background(cell, bg_col)
            set_cell_margins(cell, top=50, bottom=50, left=80, right=80)
            p = cell.paragraphs[0]
            p.alignment = alignments[c_idx]
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.line_spacing = 1.0
            run = p.add_run(str(cell_value))
            run.font.name = "Calibri"
            run.font.size = Pt(8.5)
            run.font.color.rgb = COLOR_BLACK_RGB

    p_spacer = doc.add_paragraph()
    p_spacer.paragraph_format.space_before = Pt(0)
    p_spacer.paragraph_format.space_after = Pt(2)


def add_figure_component(doc, figure_num, title, description, image_path, width_cm=14.5):
    """Insère une figure centrée haute définition accompagnée de sa légende descriptive."""
    if not os.path.exists(image_path):
        print(f"[ATTENTION] Image introuvable : {image_path}")
        return

    p_img = doc.add_paragraph()
    p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_img.paragraph_format.space_before = Pt(4)
    p_img.paragraph_format.space_after = Pt(2)
    p_img.paragraph_format.keep_with_next = True
    run_img = p_img.add_run()
    run_img.add_picture(image_path, width=Cm(width_cm))

    p_leg = doc.add_paragraph()
    p_leg.paragraph_format.space_before = Pt(1)
    p_leg.paragraph_format.space_after = Pt(6)
    p_leg.paragraph_format.line_spacing = 1.05

    r_num = p_leg.add_run(f"Figure {figure_num} : ")
    r_num.bold = True
    r_num.font.name = "Calibri"
    r_num.font.size = Pt(8.5)
    r_num.font.color.rgb = COLOR_NAVY_RGB

    r_tit = p_leg.add_run(f"{title}. ")
    r_tit.bold = True
    r_tit.font.name = "Calibri"
    r_tit.font.size = Pt(8.5)
    r_tit.font.color.rgb = COLOR_BLACK_RGB

    if description:
        r_desc = p_leg.add_run(description)
        r_desc.italic = True
        r_desc.font.name = "Calibri"
        r_desc.font.size = Pt(8.0)
        r_desc.font.color.rgb = COLOR_GREY_RGB


def add_description_paragraph(doc, text):
    """Ajoute un paragraphe de description factuelle des résultats."""
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.line_spacing = 1.15
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    run = p.add_run(text)
    run.font.name = "Calibri"
    run.font.size = Pt(10)
    run.font.color.rgb = COLOR_BLACK_RGB


def main():
    print("--> Lancement de la génération du document Word avec descriptions factuelles (style mémoire, sans interprétation)...")

    dossier_base = os.path.dirname(os.path.abspath(__file__))
    dossier_figures = os.path.join(dossier_base, "figures")
    fichier_docx_commente = os.path.join(dossier_base, "Partie_Resultats_Memoire_Commente.docx")
    fichier_docx_descriptif = os.path.join(dossier_base, "Partie_Resultats_Memoire_Descriptif.docx")

    doc = Document()
    configure_page_margins(doc)

    # =========================================================================
    # PAGE 1 : PAGE DE GARDE / EN-TÊTE ACADÉMIQUE (RECTO - DROITE)
    # =========================================================================
    p_inst = doc.add_paragraph()
    p_inst.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_inst.paragraph_format.space_before = Pt(36)
    p_inst.paragraph_format.space_after = Pt(2)
    r_inst = p_inst.add_run("UNIVERSITÉ DE MONS — FACULTÉ DES SCIENCES\nDépartement de Biologie — Laboratoire de Zoologie")
    r_inst.bold = True
    r_inst.font.name = "Calibri"
    r_inst.font.size = Pt(11)
    r_inst.font.color.rgb = COLOR_GREY_RGB

    p_main = doc.add_paragraph()
    p_main.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_main.paragraph_format.space_before = Pt(40)
    p_main.paragraph_format.space_after = Pt(12)
    r_main = p_main.add_run("RÉSULTATS DE RECHERCHE")
    r_main.bold = True
    r_main.font.name = "Calibri"
    r_main.font.size = Pt(24)
    r_main.font.color.rgb = COLOR_NAVY_RGB

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_sub.paragraph_format.space_before = Pt(0)
    p_sub.paragraph_format.space_after = Pt(8)
    r_sub = p_sub.add_run("Impact d’outils pédagogiques sur l’intérêt de la population pour la conservation et mise en évidence des difficultés d’identification")
    r_sub.bold = True
    r_sub.font.name = "Calibri"
    r_sub.font.size = Pt(14)
    r_sub.font.color.rgb = COLOR_DARK_BLUE_RGB

    p_sub2 = doc.add_paragraph()
    p_sub2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_sub2.paragraph_format.space_before = Pt(4)
    p_sub2.paragraph_format.space_after = Pt(30)
    r_sub2 = p_sub2.add_run("Évaluation de l'apprentissage taxonomique des abeilles sauvages (Hymenoptera : Apoidea)\nComparaison multi-cohortes (EPIC vs BAC 3) et analyse des pièges morphologiques")
    r_sub2.italic = True
    r_sub2.font.name = "Calibri"
    r_sub2.font.size = Pt(11.5)
    r_sub2.font.color.rgb = COLOR_GREY_RGB

    p_meta = doc.add_paragraph()
    p_meta.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_meta.paragraph_format.space_before = Pt(40)
    p_meta.paragraph_format.space_after = Pt(6)
    r_meta = p_meta.add_run("Mémoire présenté par : Paul Genné\nPromoteur : Denis Michez | Co-promotrice : Sarah Lescot\nAnnée académique 2026-2027")
    r_meta.font.name = "Calibri"
    r_meta.font.size = Pt(11)
    r_meta.font.color.rgb = COLOR_BLACK_RGB

    p_note = doc.add_paragraph()
    p_note.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_note.paragraph_format.space_before = Pt(24)
    p_note.paragraph_format.space_after = Pt(0)
    r_note = p_note.add_run("[ Document structuré en double page : Tableaux et Figures en page de gauche — Descriptions des résultats en regard en page de droite ]")
    r_note.italic = True
    r_note.font.name = "Calibri"
    r_note.font.size = Pt(9.5)
    r_note.font.color.rgb = RGBColor(120, 130, 140)

    # =========================================================================
    # SPREAD 1 (Pages 2-3) : AXE A — TRAJECTOIRES GLOBALES DES SCORES
    # =========================================================================
    doc.add_page_break()

    # --- PAGE 2 (GAUCHE - VERSO) : DONNÉES BLOC 1 ---
    add_custom_heading(doc, "1. Axe A — Évaluation et dynamique de l'apprentissage taxonomique", level=1)
    add_custom_heading(doc, "1.1 Trajectoires globales d'évolution des scores", level=2)

    # Tableau 1A
    t2a_headers = ["Cohorte & Année", "Échantillon", "Score Pré (Moy ± ET)", "Score Post (Moy ± ET)", "Gain brut (Δ)", "Gain relatif"]
    t2a_rows = [
        ["EPIC 2025 (Adultes)", "50 Pré / 49 Post", "10,51 ± 4,69", "16,53 ± 2,22", "+6,02 pts", "+30,1 %"],
        ["BAC 3 (2024) (Étudiants)", "25 paires strictes", "6,61 ± 3,21", "14,06 ± 2,76", "+7,45 pts", "+37,2 %"],
        ["BAC 3 (2025) (Étudiants)", "22 paires strictes", "9,33 ± 4,33", "15,26 ± 2,64", "+5,93 pts", "+29,7 %"],
        ["EPIC 2026 (Transversal)", "64 Formés / 108 Témoins", "15,91 ± 3,43", "16,53 ± 2,77", "+0,62 pt", "+3,1 %"],
    ]
    t2a_widths = [Cm(3.5), Cm(3.1), Cm(2.7), Cm(2.7), Cm(2.4), Cm(2.4)]
    t2a_aligns = [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER,
                  WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER]
    add_table_component(
        doc, table_num="1A",
        title="Performances descriptives Pré vs Post et gains observés (sur 20 points)",
        description="Moyennes et écarts-types des scores standardisés sur 20 points, accompagnés des gains absolus et pourcentages d'amélioration observés dans les cohortes.",
        headers=t2a_headers, data_rows=t2a_rows, col_widths=t2a_widths, alignments=t2a_aligns
    )

    # Figure 1
    add_figure_component(
        doc, figure_num=1,
        title="Trajectoires d'évolution des scores Pré vs Post à travers les cohortes",
        description="Évolution des scores moyens et distributions individuelles (sur 20 points) entre pré-test et post-test. Les barres d'erreur représentent l'intervalle de confiance à 95 % de la moyenne. Les trois cohortes longitudinales affichent un bond homogène de +6 à +7,5 points.",
        image_path=os.path.join(dossier_figures, "fig2_trajectoires_intercohortes.png"),
        width_cm=14.5
    )

    doc.add_page_break()

    # --- PAGE 3 (DROITE - RECTO) : DESCRIPTION BLOC 1 ---
    add_custom_heading(doc, "Description des résultats : Évolution des scores pré- et post-formation", level=2)

    add_description_paragraph(
        doc,
        "Comme l'illustrent conjointement le Tableau 1A et la Figure 1, l'évaluation des compétences initiales lors des pré-tests "
        "met en évidence une disparité sensible entre les publics étudiés. Avant toute formation, les adultes naturalistes du programme "
        "EPIC 2025 obtiennent une note moyenne de 10,51 ± 4,69 sur 20 (médiane de 10,00), tandis que les étudiants de troisième année de "
        "bachelier (Bac 3) enregistrent des scores moyens initiaux de 6,61 ± 3,21 (médiane de 6,92) lors de la session 2024 et de 9,33 ± 4,33 "
        "(médiane de 10,35) lors de la session 2025."
    )

    add_description_paragraph(
        doc,
        "À l'issue de l'intervention pédagogique, l'ensemble des cohortes suivies longitudinalement enregistre une progression marquée de "
        "leurs performances. Chez les étudiants, le gain brut moyen mesuré est de +7,45 points sur 20 (+37,2 % en 2024) et de +5,93 points "
        "(+29,7 % en 2025), portant les moyennes finales respectives à 14,06 ± 2,76 et 15,26 ± 2,64. De manière comparable, les adultes "
        "du programme EPIC 2025 progressent en moyenne de +6,02 points (+30,1 %), pour atteindre un score moyen post-formation de 16,53 ± 2,22 "
        "(médiane de 16,67). La Figure 1 illustre cette tendance au niveau individuel, montrant une trajectoire ascendante pour la quasi-totalité "
        "des participants et un regroupement prononcé des scores finaux au-dessus du seuil de 14/20."
    )

    add_description_paragraph(
        doc,
        "Dans la cohorte transversale EPIC 2026, les adultes ayant suivi le cycle de formation obtiennent une note moyenne de 16,53 ± 2,77 "
        "(médiane de 17,33), contre 15,91 ± 3,43 (médiane de 16,67) pour le groupe témoin d'adultes non formés, ce qui correspond à un écart "
        "brut mesuré de +0,62 point (+3,1 %)."
    )

    # =========================================================================
    # SPREAD 2 (Pages 4-5) : AXE A — INFERENCES STATISTIQUES ET TAILLES D'EFFET
    # =========================================================================
    doc.add_page_break()

    # --- PAGE 4 (GAUCHE - VERSO) : DONNÉES BLOC 2 ---
    add_custom_heading(doc, "1. Axe A — Évaluation et dynamique de l'apprentissage taxonomique", level=1)
    add_custom_heading(doc, "1.2 Tests inférentiels et amplitudes des effets", level=2)

    # Tableau 1B
    t2b_headers = ["Cohorte & Année", "Test inférentiel", "Valeur p", "d de Cohen", "r de Rosenthal", "Odds Ratio ajusté [IC 95 %]"]
    t2b_rows = [
        ["EPIC 2025", "Wilcoxon Mann-Whitney (W = 2103)", "< 0,001", "1,64", "0,62", "3,94 [2,74 - 5,66]"],
        ["BAC 3 (2024)", "Wilcoxon apparié (V = 325)", "< 0,001", "2,73", "0,62", "5,54 [3,77 - 8,14]"],
        ["BAC 3 (2025)", "Wilcoxon apparié (V = 252)", "< 0,001", "1,40", "0,61", "4,37 [2,73 - 6,98]"],
        ["EPIC 2026", "GLM multivarié (t = -2,02)", "0,046", "0,19", "0,07", "1,42 [1,01 - 2,01]"],
    ]
    t2b_widths = [Cm(2.6), Cm(4.4), Cm(1.8), Cm(1.8), Cm(1.8), Cm(4.4)]
    t2b_aligns = [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER,
                  WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER]
    add_table_component(
        doc, table_num="1B",
        title="Tests statistiques inférentiels et tailles d'effet de l'apprentissage",
        description="Tests d'hypothèses univariés et multivariés, tailles d'effet de Cohen (d) et Rosenthal (r), et Odds Ratios ajustés pour le temps de passation avec intervalles de confiance à 95 %.",
        headers=t2b_headers, data_rows=t2b_rows, col_widths=t2b_widths, alignments=t2b_aligns
    )

    # Figure 2
    add_figure_component(
        doc, figure_num=2,
        title="Forest Plot des tailles d'effet de l'apprentissage taxonomique",
        description="Représentation comparée des tailles d'effet. À gauche : indice d de Cohen (d > 0,80 indique un effet fort, culminant à 1,40 - 2,73). À droite : Odds Ratios ajustés et leurs intervalles de confiance à 95 % issus des modélisations GLM multivariées.",
        image_path=os.path.join(dossier_figures, "fig3_forest_plot_tailles_effet.png"),
        width_cm=14.5
    )

    doc.add_page_break()

    # --- PAGE 5 (DROITE - RECTO) : DESCRIPTION BLOC 2 ---
    add_custom_heading(doc, "Description des résultats : Tests d'hypothèses et tailles d'effet", level=2)

    add_description_paragraph(
        doc,
        "L'analyse inférentielle confirme la significativité statistique de la progression mesurée entre le pré-test et le post-test au sein de "
        "chaque cohorte (Tableau 1B et Figure 2). Les tests non paramétriques révèlent une différence hautement significative pour l'ensemble des "
        "suivis longitudinaux : test de Wilcoxon-Mann-Whitney pour la cohorte EPIC 2025 (W = 2103, p = 7,69 × 10⁻¹⁰) et tests des rangs signés "
        "de Wilcoxon apparié pour les deux promotions d'étudiants (V = 325, p = 5,96 × 10⁻⁸ en 2024 ; V = 252, p = 1,19 × 10⁻⁶ en 2025)."
    )

    add_description_paragraph(
        doc,
        "L'évaluation de l'amplitude de cet effet met en évidence des valeurs élevées à travers les différents indices calculés. L'indice d de Cohen "
        "paramétrique s'établit à 1,64 pour EPIC 2025, 2,73 pour BAC 3 2024 et 1,40 pour BAC 3 2025, se situant au-delà du seuil conventionnel d'effet "
        "fort (d > 0,80). Parallèlement, le coefficient de corrélation de rang r de Rosenthal présente une valeur remarquablement stable d'une cohorte "
        "à l'autre, s'établissant à r = 0,62 pour EPIC 2025, r = 0,62 pour BAC 3 2024 et r = 0,61 pour BAC 3 2025."
    )

    add_description_paragraph(
        doc,
        "Cette régularité est étayée par les modèles linéaires généralisés (GLM logistiques) ajustés en contrôlant pour la durée de passation de l'épreuve "
        "(Figure 2, volet droit). Les Odds Ratios de réussite associés à la session post-formation atteignent 3,94 [IC 95 % : 2,74 - 5,66] chez EPIC 2025, "
        "5,54 [IC 95 % : 3,77 - 8,14] chez BAC 3 2024 et 4,37 [IC 95 % : 2,73 - 6,98] chez BAC 3 2025. "
        "Pour la cohorte transversale EPIC 2026, le modèle multivarié contrôlant pour la région et le temps passé met en évidence un effet significatif "
        "du statut de formation (t = -2,02, p = 0,046), avec un Odds Ratio ajusté de 1,42 [IC 95 % : 1,01 - 2,01] (d = 0,19, r = 0,07)."
    )

    # =========================================================================
    # SPREAD 3 (Pages 6-7) : AXE A — DISTRIBUTIONS ET RÉDUCTION DU DOUTE
    # =========================================================================
    doc.add_page_break()

    # --- PAGE 6 (GAUCHE - VERSO) : DONNÉES BLOC 3 ---
    add_custom_heading(doc, "1. Axe A — Évaluation et dynamique de l'apprentissage taxonomique", level=1)
    add_custom_heading(doc, "1.3 Distributions des scores et réponses d'abstention", level=2)

    # Figure 3
    add_figure_component(
        doc, figure_num=3,
        title="Distributions et densités des scores avant et après formation",
        description="Densités des scores avant (rouge) et après (vert) apprentissage (cohorte EPIC 2025). Illustration de l'effet plafond post-formation (Shapiro-Wilk p < 0,01) et du resserrement massif de la dispersion (variance divisée par plus de 4, Fligner-Killeen p < 0,001).",
        image_path=os.path.join(dossier_figures, "fig4_distributions_scores.png"),
        width_cm=14.0
    )

    # Figure 4
    add_figure_component(
        doc, figure_num=4,
        title="Effondrement de l'abstention et des réponses « Je ne sais pas »",
        description="Proportion d'items avec réponse d'évitement ou d'abstention avant et après apprentissage. Chute universelle de l'incertitude comprise entre -85,3 % et -92,2 % à travers toutes les cohortes suivies longitudinalement.",
        image_path=os.path.join(dossier_figures, "fig5_effondrement_idk.png"),
        width_cm=14.0
    )

    doc.add_page_break()

    # --- PAGE 7 (DROITE - RECTO) : DESCRIPTION BLOC 3 ---
    add_custom_heading(doc, "Description des résultats : Forme des distributions et abstention", level=2)

    add_description_paragraph(
        doc,
        "L'analyse de la morphologie des distributions de notes met en évidence une modification structurelle marquée entre les épreuves "
        "pré- et post-formation (Figures 3 et 4). En pré-test, la distribution des scores de la cohorte EPIC 2025 présente une allure étalée couvrant "
        "l'ensemble de l'échelle (de 2 à 18 points), avec un sommet centré autour de 10 points. En post-test, la courbe de densité bascule vers la droite "
        "et adopte une asymétrie négative prononcée, avec une concentration des observations entre 15 et 18 points (Figure 3). "
        "Le test de normalité de Shapiro-Wilk confirme le rejet de l'hypothèse de normalité en post-test (W = 0,9338, p = 0,0085 pour EPIC 2025 ; "
        "W = 0,896, p < 0,001 pour EPIC 2026), traduisant l'existence d'un effet plafond."
    )

    add_description_paragraph(
        doc,
        "Cette transformation s'accompagne d'une réduction nette de la dispersion des scores individuels. Le test d'homogénéité des variances "
        "de Fligner-Killeen indique une hétéroscédasticité significative entre les deux sessions (χ² = 17,21, p = 3,35 × 10⁻⁵ chez EPIC 2025 ; "
        "χ² = 6,84, p = 0,0089 chez BAC 3 2024). Chez EPIC 2025, la variance des notes passe de 22,0 en pré-test à 4,9 en post-test, soit une "
        "division par un facteur de 4,5 de la variabilité des résultats."
    )

    add_description_paragraph(
        doc,
        "Parallèlement, la fréquence des réponses d'évitement ou d'abstention (« Je ne sais pas » et omissions) enregistre une chute marquée "
        "dans toutes les cohortes suivies longitudinalement (Figure 4). Pour la cohorte EPIC 2025, le taux d'abstention passe de 27,1 % en pré-test "
        "à 2,4 % en post-test, représentant une diminution absolue de 24,7 points de pourcentage (réduction relative de -91,0 %). "
        "Pour la promotion BAC 3 2024, ce taux passe de 37,7 % à 5,5 % (-32,2 points, soit une réduction de -85,3 %). "
        "Pour BAC 3 2025, il décroît de 20,3 % à 1,6 % (-18,7 points, soit une réduction de -92,2 %)."
    )

    # =========================================================================
    # SPREAD 4 (Pages 8-9) : AXE A — DUREE ET FACTEURS BIOLOGIQUES
    # =========================================================================
    doc.add_page_break()

    # --- PAGE 8 (GAUCHE - VERSO) : DONNÉES BLOC 4 ---
    add_custom_heading(doc, "1. Axe A — Évaluation et dynamique de l'apprentissage taxonomique", level=1)
    add_custom_heading(doc, "1.4 Durée de passation et facteurs biologiques (Sexe & Guilde)", level=2)

    # Figure 5
    add_figure_component(
        doc, figure_num=5,
        title="Relation entre la durée totale de passation et la performance",
        description="Régression entre temps de complétion (minutes) et score final. En post-test, un temps de réponse prolongé traduit des hésitations sur les genres morphologiquement ambigus et s'associe à un score inférieur (beta = -0,0094, p = 0,0018).",
        image_path=os.path.join(dossier_figures, "fig6_duree_vs_performance.png"),
        width_cm=14.0
    )

    # Figure 6
    add_figure_component(
        doc, figure_num=6,
        title="Taux de succès selon le sexe du spécimen et la guilde écologique",
        description="Taux d'identification correcte selon le sexe (mâles vs femelles) et la guilde (pollinisateurs non-parasites vs cléptoparasites coucous). Absence d'interaction Formation x Sexe (p = 0,393) et gain plus marqué sur les coucous (+37,1 % vs +27,6 %).",
        image_path=os.path.join(dossier_figures, "fig7_facteurs_biologiques_sexe_guilde.png"),
        width_cm=14.0
    )

    doc.add_page_break()

    # --- PAGE 9 (DROITE - RECTO) : DESCRIPTION BLOC 4 ---
    add_custom_heading(doc, "Description des résultats : Durée du test, sexe et guilde des spécimens", level=2)

    add_description_paragraph(
        doc,
        "L'examen des variables individuelles et biologiques met en relief des relations différenciées avec la réussite de l'identification "
        "(Figures 5 et 6). En ce qui concerne la durée totale de passation (Figure 5), aucune corrélation linéaire significative n'est observée "
        "en pré-test entre le temps passé et le score obtenu (r = 0,18, p = 0,21). En revanche, lors du post-test et dans le modèle multivarié "
        "de la cohorte transversale EPIC 2026, la pente de régression associée à la durée devient négative et significative (β = -0,0094, t = -3,17, "
        "p = 0,0018), indiquant une diminution moyenne de la note à mesure que le temps de complétion dépasse la durée médiane du groupe."
    )

    add_description_paragraph(
        doc,
        "L'analyse selon les caractères biologiques des spécimens révèle une dynamique contrastée entre le sexe et la guilde écologique (Figure 6). "
        "Concernant le sexe des spécimens (volet gauche), les individus mâles passent d'un taux de succès de 46,2 % en pré-test à 75,0 % en post-test "
        "(+28,8 points, test de Fisher OR = 0,250, p = 4,2 × 10⁻³³), tandis que les femelles passent de 49,8 % à 81,2 % (+31,4 points, OR = 0,216, "
        "p = 2,9 × 10⁻³⁹). Le test d'interaction Session × Sexe au sein du modèle logistique n'est pas statistiquement significatif (p = 0,393), "
        "attestant d'une progression équivalente pour les deux sexes."
    )

    add_description_paragraph(
        doc,
        "Concernant la guilde écologique (volet droit), les abeilles pollinisatrices non parasites partent d'un taux initial de 55,8 % et atteignent "
        "83,4 % en post-test (+27,6 points, OR = 0,255, p = 3,6 × 10⁻⁴⁵). Les abeilles cléptoparasites (genres coucous Nomada, Sphecodes, Stelis, "
        "Melecta, Coelioxys, caractérisées par un habitus glabre dépourvu d'appareil de récolte du pollen) partent d'un taux initial plus bas de 33,3 %, "
        "mais atteignent 70,4 % après formation (+37,1 points, OR = 0,196, p = 8,9 × 10⁻²⁷), soit un gain brut supérieur de +9,5 points de pourcentage "
        "comparativement aux formes non-parasites."
    )

    # =========================================================================
    # SPREAD 5 (Pages 10-11) : AXE A — MODELE GLM INTERACTION PUBLIC X FORMATION
    # =========================================================================
    doc.add_page_break()

    # --- PAGE 10 (GAUCHE - VERSO) : DONNÉES BLOC 5 ---
    add_custom_heading(doc, "1. Axe A — Évaluation et dynamique de l'apprentissage taxonomique", level=1)
    add_custom_heading(doc, "1.5 Modèle d'interaction Public × Formation (GLM Quasibinomial)", level=2)

    # Tableau 2
    t3_headers = ["Terme du modèle", "Coefficient (β)", "Erreur Std", "Statistique t", "Valeur p", "Odds Ratio [IC 95 %]"]
    t3_rows = [
        ["Constante (Étudiants - Pré-test)", "-0,4295", "0,1127", "-3,811", "0,00019 ***", "0,65 [0,52 - 0,81]"],
        ["Effet Public (Adultes EPIC)", "+0,5308", "0,1554", "+3,417", "0,00078 ***", "1,70 [1,25 - 2,31]"],
        ["Effet Formation (Post-test)", "+1,4297", "0,1677", "+8,524", "< 10^-14 ***", "4,18 [3,01 - 5,80]"],
        ["Interaction (Adultes x Formation)", "+0,0299", "0,2447", "+0,122", "0,903 (NS)", "1,03 [0,64 - 1,66]"],
    ]
    t3_widths = [Cm(4.5), Cm(2.2), Cm(2.2), Cm(1.8), Cm(2.3), Cm(3.2)]
    t3_aligns = [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER,
                 WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER]
    add_table_component(
        doc, table_num="2",
        title="Modèle Linéaire Généralisé Quasibinomial testant l'interaction Public × Formation",
        description="Coefficients de régression logistique quasibinomiale ajustés sur l'ensemble des 5 160 observations longitudinales. L'absence d'interaction significative confirme que les adultes et les étudiants progressent avec la même intensité.",
        headers=t3_headers, data_rows=t3_rows, col_widths=t3_widths, alignments=t3_aligns
    )

    doc.add_page_break()

    # --- PAGE 11 (DROITE - RECTO) : DESCRIPTION BLOC 5 ---
    add_custom_heading(doc, "Description des résultats : Modélisation conjointe de l'interaction", level=2)

    add_description_paragraph(
        doc,
        "Le Tableau 2 rassemble les paramètres d'ajustement du Modèle Linéaire Généralisé (GLM) Quasibinomial à fonction de lien logit, testant "
        "sur 5 160 observations longitudinales les effets respectifs du type de public (référence : étudiants de Bac 3), de la session (référence : pré-test) "
        "et de leur interaction conjointe Public × Session."
    )

    add_description_paragraph(
        doc,
        "La constante du modèle (cote de succès des étudiants en pré-test) s'établit à β = -0,4295 ± 0,1127 (t = -3,811, p = 0,00019, "
        "Odds Ratio = 0,651 [IC 95 % : 0,522 - 0,812]). L'effet principal associé au public adulte présente un coefficient positif et statistiquement "
        "significatif : β = +0,5308 ± 0,1554 (t = 3,417, p = 0,00078), avec un Odds Ratio de 1,700 [IC 95 % : 1,254 - 2,306], quantifiant une cote de réussite "
        "en pré-test significativement plus élevée chez les adultes que chez les étudiants."
    )

    add_description_paragraph(
        doc,
        "L'effet principal de la Formation (session post-test) est positif et hautement significatif : β = +1,4297 ± 0,1677 (t = 8,524, p = 4,85 × 10⁻¹⁵), "
        "correspondant à un Odds Ratio de 4,177 [IC 95 % : 3,007 - 5,803]. Pour le groupe de référence des étudiants, la cote de succès est multipliée "
        "par 4,18 entre le pré-test et le post-test."
    )

    add_description_paragraph(
        doc,
        "Enfin, le terme d'interaction Public × Formation affiche une valeur de β = +0,0299 ± 0,2447 (statistique t = 0,122, p = 0,903, "
        "Odds Ratio = 1,030 [IC 95 % : 0,638 - 1,664]). La valeur p de 0,903 indique l'absence d'écart statistiquement significatif entre "
        "les coefficients de progression des adultes et des étudiants."
    )

    # =========================================================================
    # SPREAD 6 (Pages 12-13) : AXE B — GRADIENT ET MODÈLE LOGISTIQUE DES GENRES
    # =========================================================================
    doc.add_page_break()

    # --- PAGE 12 (GAUCHE - VERSO) : DONNÉES BLOC 6 ---
    add_custom_heading(doc, "2. Axe B — Identification des genres pièges et analyse des confusions", level=1)
    add_custom_heading(doc, "2.1 Gradient consensuel de difficulté et cotes relatives par genre", level=2)

    # Figure 7
    add_figure_component(
        doc, figure_num=7,
        title="Gradient de difficulté taxonomique consensuel des 27 genres d'abeilles sauvages",
        description="Taux d'erreur moyen résiduel post-formation par genre d'abeille avec intervalles de confiance de Wilson à 95 %. Les couleurs illustrent les quatre paliers d'assimilation cognitive (Très difficile, Modéré, Accessible, Facile).",
        image_path=os.path.join(dossier_figures, "fig8_consensus_difficulte_genres.png"),
        width_cm=14.0
    )

    # Figure 8
    add_figure_component(
        doc, figure_num=8,
        title="Forest Plot des Odds Ratios de difficulté par genre (vs Bombus — Synthèse inter-cohortes)",
        description="Odds Ratios issus de la régression logistique binomiale ajustée sur 2 466 identifications post-formation (toutes cohortes confondues), prenant le genre Bombus comme niveau de référence universel (OR = 1,00). Les barres horizontales indiquent les intervalles de confiance à 95 % (les valeurs p sont corrigées par le taux de fausse découverte FDR).",
        image_path=os.path.join(dossier_figures, "fig9_forest_plot_or_genres.png"),
        width_cm=14.0
    )

    doc.add_page_break()

    # --- PAGE 13 (DROITE - RECTO) : DESCRIPTION BLOC 6 ---
    add_custom_heading(doc, "Description des résultats : Gradient de difficulté et Odds Ratios par genre", level=2)

    add_description_paragraph(
        doc,
        "La Figure 7 illustre le classement décroissant des 27 genres d'abeilles sauvages évalués selon leur taux d'erreur moyen en post-formation, "
        "assorti des intervalles de confiance de Wilson à 95 %. Les taux d'erreur mesurés s'échelonnent de 0,0 % à 57,4 %, faisant apparaître "
        "quatre regroupements distincts :"
    )

    add_description_paragraph(
        doc,
        "• Sept genres présentent un taux d'erreur post-formation supérieur ou égal à 35 % : Stelis (57,4 %, IC 95 % : [43,3 - 70,5 %]), "
        "Trachusa (54,5 %, IC : [34,7 - 73,1 %]), Anthophora (53,1 %, IC : [43,2 - 62,8 %]), Lasioglossum (45,8 %, IC : [37,0 - 54,7 %]), "
        "Megachile (43,0 %, IC : [34,5 - 51,9 %]), Sphecodes (42,2 %, IC : [35,4 - 49,3 %]) et Chelostoma (38,8 %, IC : [26,4 - 52,8 %]).\n"
        "• Six genres enregistrent un taux d'erreur intermédiaire compris entre 20 % et 34 % : Andrena (30,2 %, IC : [24,2 - 37,0 %]), "
        "Osmia (28,1 %, IC : [20,1 - 37,8 %]), Ammobates (26,5 %, IC : [16,2 - 40,3 %]), Eucera (22,0 %, IC : [15,5 - 30,3 %]), "
        "Hoplitis (20,4 %, IC : [11,5 - 33,6 %]) et Melecta (20,4 %, IC : [11,5 - 33,6 %])."
    )

    add_description_paragraph(
        doc,
        "• Sept genres présentent un taux d'erreur compris entre 10 % et 19 % : Nomada (18,8 %), Epeolus (18,4 %), Panurgus (17,7 %), "
        "Anthidium (14,6 %), Colletes (14,6 %), Ceratina (11,5 %) et Macropis (10,2 %).\n"
        "• Sept genres affichent un taux d'erreur inférieur à 10 % : Coelioxys (8,2 %), Halictus (7,6 %), Hylaeus (7,3 %), Bombus (6,0 %), "
        "Apis (4,2 %), Dasypoda (4,2 %) et Xylocopa (0,0 %, IC : [0,0 - 3,8 %])."
    )

    add_description_paragraph(
        doc,
        "La Figure 8 rapporte les Odds Ratios (OR) issus de la régression logistique binomiale modélisant la cote de réussite relative par genre "
        "sur l'ensemble des 2 466 identifications post-formation inter-cohortes, prenant le genre Bombus comme référence (OR = 1,00, taux de succès de 94,0 %). "
        "Dix-huit des 26 genres comparés présentent un déficit de cote de réussite statistiquement significatif par rapport à Bombus (p_adj < 0,05 après correction FDR) :"
    )

    add_description_paragraph(
        doc,
        "• Les cotes de succès relatives les plus basses concernent les sept genres du palier très difficile (≥ 35 % d'erreur) : "
        "Stelis (OR = 0,047, IC 95 % : [0,021 - 0,106], p_adj = 7,32 × 10⁻¹³), Trachusa (OR = 0,053, IC : [0,019 - 0,146], p_adj = 4,60 × 10⁻⁸), "
        "Anthophora (OR = 0,056, IC : [0,028 - 0,112], p_adj = 7,33 × 10⁻¹⁵), Lasioglossum (OR = 0,076, IC : [0,039 - 0,147], p_adj = 2,97 × 10⁻¹³), "
        "Megachile (OR = 0,085, IC : [0,043 - 0,165], p_adj = 1,98 × 10⁻¹²), Sphecodes (OR = 0,087, IC : [0,047 - 0,164], p_adj = 2,97 × 10⁻¹³) "
        "et Chelostoma (OR = 0,101, IC : [0,045 - 0,225], p_adj = 6,98 × 10⁻⁸).\n"
        "• Les genres de difficulté intermédiaire (20 à 34 % d'erreur) affichent également un désavantage très net : "
        "Andrena (OR = 0,147, IC : [0,078 - 0,279], p_adj = 1,97 × 10⁻⁸), Osmia (OR = 0,163, IC : [0,080 - 0,333], p_adj = 2,01 × 10⁻⁶), "
        "Ammobates (OR = 0,176, IC : [0,076 - 0,411], p_adj = 1,45 × 10⁻⁴), Eucera (OR = 0,225, IC : [0,111 - 0,459], p_adj = 1,06 × 10⁻⁴), "
        "ainsi que Hoplitis et Melecta (OR = 0,249, IC : [0,102 - 0,607], p_adj = 0,0040).\n"
        "• Au sein des genres accessibles (10 à 19 % d'erreur), cinq genres conservent une cote de réussite inférieure de façon significative à Bombus : "
        "Nomada (OR = 0,276, p_adj = 0,00036), Epeolus (OR = 0,283, p_adj = 0,0116), Panurgus (OR = 0,296, p_adj = 0,0039), "
        "Colletes (OR = 0,373, p_adj = 0,0231) et Anthidium (OR = 0,373, p_adj = 0,0231).\n"
        "• En revanche, huit genres ne présentent pas d'écart statistiquement significatif avec Bombus (p_adj > 0,05) : "
        "Ceratina (OR = 0,492, p_adj = 0,134), Macropis (OR = 0,561, p_adj = 0,379), Coelioxys (OR = 0,717, p_adj = 0,620), "
        "Halictus (OR = 0,772, p_adj = 0,620), Hylaeus (OR = 0,810, p_adj = 0,620), Dasypoda et Apis (OR = 1,466, IC : [0,465 - 4,617], p_adj = 0,603), "
        "et Xylocopa (OR = 12,17, IC : [0,715 - 207,3], p_adj = 0,119 ; 100 % de succès avec correction de continuité de Haldane-Anscombe)."
    )

    # =========================================================================
    # SPREAD 7 (Pages 14-15) : AXE B — GAINS PAR GENRE ET MATRICE DE CONFUSION
    # =========================================================================
    doc.add_page_break()

    # --- PAGE 14 (GAUCHE - VERSO) : DONNÉES BLOC 7 ---
    add_custom_heading(doc, "2. Axe B — Identification des genres pièges et analyse des confusions", level=1)
    add_custom_heading(doc, "2.2 Gains d'apprentissage par genre et matrice globale de confusion", level=2)

    # Figure 9
    add_figure_component(
        doc, figure_num=9,
        title="Volcano Plot des gains d'apprentissage par genre d'abeille",
        description="Gain absolu de réussite (Post - Pré) versus niveau de significativité statistique (-log10 de la p-value ajustée de Fisher avec correction FDR). Les genres en vert constituent les cibles d'un apprentissage hautement significatif.",
        image_path=os.path.join(dossier_figures, "fig10_volcano_gains_genres.png"),
        width_cm=14.0
    )

    # Figure 10
    add_figure_component(
        doc, figure_num=10,
        title="Matrice de confusion taxonomique globale post-formation",
        description="Distribution des réponses fournies par les apprenants (colonnes) pour chaque spécimen réel testé (lignes). La diagonale représente les identifications correctes ; les cases hors diagonale mettent en évidence les confusions récurrentes.",
        image_path=os.path.join(dossier_figures, "fig11_matrice_confusions.png"),
        width_cm=14.0
    )

    doc.add_page_break()

    # --- PAGE 15 (DROITE - RECTO) : DESCRIPTION BLOC 7 ---
    add_custom_heading(doc, "Description des résultats : Gains par genre et transferts d'erreurs", level=2)

    add_description_paragraph(
        doc,
        "La Figure 9 présente le Volcano Plot des gains de réussite genre par genre. L'axe des abscisses indique le gain brut (pourcentage en post-test "
        "moins pourcentage en pré-test), tandis que l'axe des ordonnées porte le degré de significativité statistique, exprimé par -log₁₀ de la p-value "
        "ajustée du test exact de Fisher (correction de Benjamini-Hochberg, FDR). La ligne horizontale en pointillés marque le seuil p_adj = 0,05."
    )

    add_description_paragraph(
        doc,
        "Cinq genres se situent au-dessus du seuil de significativité avec des gains élevés (points verts) : Seladonia (+35,8 points de gain, p_adj = 0,0085), "
        "Nomada (+34,7 points, p_adj < 10⁻⁴), Hylaeus (+32,7 points, p_adj < 10⁻⁴), Anthidium (+29,6 points, p_adj = 0,0042) et Ammobates (+22,4 points, "
        "p_adj = 0,0074). Les genres Megachile (+13,2 points, p_adj = 0,025), Anthophora (+14,1 points) et Lasioglossum (+12,8 points) enregistrent "
        "des gains de moindre amplitude, plusieurs d'entre eux se situant sous le seuil de significativité ajusté."
    )

    add_description_paragraph(
        doc,
        "La Figure 10 affiche la matrice globale des confusions post-formation, croisant les 27 genres cibles réels (en lignes) avec les déterminations "
        "fournies par les observateurs (en colonnes). La diagonale principale indique des taux d'identification exacte supérieurs à 80 % pour 17 taxons "
        "(avec un maximum de 100 % pour Xylocopa, 95,8 % pour Apis et Dasypoda, et 94,0 % pour Bombus)."
    )

    add_description_paragraph(
        doc,
        "Hors diagonale, les cases colorées mettent en évidence des reports d'erreurs asymétriques : les spécimens du genre Sphecodes sont principalement "
        "déterminés comme appartenant au genre Nomada ; les spécimens d'Anthophora sont fréquemment rattachés à Bombus ou à Andrena ; "
        "les spécimens de Lasioglossum sont reportés vers Halictus ou Ceratina ; et les spécimens de Stelis sont reportés vers Osmia ou Anthidium."
    )

    # =========================================================================
    # SPREAD 8 (Pages 16-17) : AXE B — CAUSES MORPHOLOGIQUES DES CONFUSIONS
    # =========================================================================
    doc.add_page_break()

    # --- PAGE 16 (GAUCHE - VERSO) : DONNÉES BLOC 8 ---
    add_custom_heading(doc, "2. Axe B — Identification des genres pièges et analyse des confusions", level=1)
    add_custom_heading(doc, "2.3 Principales paires de confusions et critères morphologiques", level=2)

    # Figure 11
    add_figure_component(
        doc, figure_num=11,
        title="Principales paires de confusions taxonomiques enregistrées",
        description="Fréquence relative des cinq paires d'erreurs dominantes observées lors des épreuves d'identification.",
        image_path=os.path.join(dossier_figures, "fig12_top_confusions_taxonomiques.png"),
        width_cm=13.5
    )

    # Tableau 3
    t5_headers = ["Confusion observée", "Part des erreurs", "Familles", "Critère morphologique discriminant clé"]
    t5_rows = [
        ["Sphecodes -> Nomada", "58,3 %", "Halictidae -> Apidae", "Abdomen rouge/noir glabre ; nervure basale coudée chez Sphecodes."],
        ["Anthophora -> Bombus", "44,1 %", "Apidae -> Apidae", "Toison dense et allure trapue ; corbicula chez Bombus vs scopa chez Anthophora."],
        ["Lasioglossum -> Halictus", "36,7 %", "Halictidae -> Halictidae", "Taille et habitus proches ; soies basales (Lasioglossum) vs apicales (Halictus)."],
        ["Megachile -> Osmia", "31,2 %", "Megachilidae -> Megachilidae", "Brosse ventrale commune ; cuticule sombre (Megachile) vs reflets bronzés (Osmia)."],
        ["Stelis -> Anthidium", "28,9 %", "Megachilidae -> Megachilidae", "Macules jaunes sur fond noir ; absence totale de brosse ventrale chez Stelis."],
    ]
    t5_widths = [Cm(3.4), Cm(1.9), Cm(3.2), Cm(7.9)]
    t5_aligns = [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT]
    add_table_component(
        doc, table_num="3",
        title="Principales confusions taxonomiques et critères morphologiques discriminants",
        description="Caractérisation des cinq paires d'erreurs dominantes, part relative dans les erreurs du taxon cible et critères anatomiques sous-jacents expliquant le piège visuel.",
        headers=t5_headers, data_rows=t5_rows, col_widths=t5_widths, alignments=t5_aligns
    )

    doc.add_page_break()

    # --- PAGE 17 (DROITE - RECTO) : DESCRIPTION BLOC 8 ---
    add_custom_heading(doc, "Description des résultats : Analyse des paires de confusions dominantes", level=2)

    add_description_paragraph(
        doc,
        "La Figure 11 et le Tableau 3 récapitulent la distribution et les caractères morphologiques des cinq paires de confusions taxonomiques "
        "les plus fréquentes observées lors des épreuves."
    )

    add_description_paragraph(
        doc,
        "La première confusion concerne Sphecodes déterminé à tort comme Nomada, représentant 58,3 % de l'ensemble des réponses erronées enregistrées "
        "sur les spécimens de Sphecodes. Le Tableau 3 indique que cette confusion s'opère entre deux familles différentes (Halictidae pour Sphecodes "
        "et Apidae pour Nomada), qui partagent un gastre partiellement rouge et un tégument noir glabre. Le caractère morphologique discriminant "
        "est la nervation alaire, la nervure basale étant fortement coudée chez Sphecodes."
    )

    add_description_paragraph(
        doc,
        "La deuxième confusion associe Anthophora et Bombus, représentant 44,1 % des erreurs sur Anthophora. Tous deux appartenant aux Apidae, "
        "ces taxons présentent une silhouette trapue et une toison dense. Le critère discriminant renseigné réside dans la patte postérieure : la femelle "
        "d'Anthophora possède une scopa tibiale velue, alors que celle de Bombus présente une corbicula glabre bordée de soies rigides."
    )

    add_description_paragraph(
        doc,
        "La troisième confusion concerne Lasioglossum attribué à Halictus (36,7 % des erreurs sur Lasioglossum), deux genres d'Halictidae de petite taille "
        "et de teinte sombre. Le critère distinctif répertorié est la position des bandes de soies tomenteuses sur les tergites abdominaux : "
        "basales chez Lasioglossum et apicales chez Halictus."
    )

    add_description_paragraph(
        doc,
        "Enfin, les quatrième et cinquième paires concernent des taxons de la famille des Megachilidae : Megachile attribué à Osmia (31,2 % des erreurs "
        "sur Megachile), deux genres caractérisés par une brosse de récolte ventrale abdominale (différenciés par la teinte cuticulaire sombre chez Megachile "
        "et à reflets métalliques chez Osmia) ; et Stelis attribué à Anthidium (28,9 % des erreurs sur Stelis), deux taxons à macules jaunes sur fond noir "
        "se distinguant par l'absence de brosse ventrale chez Stelis, liée à son statut de cléptoparasite."
    )

    # =========================================================================
    # SPREAD 9 (Pages 18-19) : SYNTHÈSE SYNOPTIQUE
    # =========================================================================
    doc.add_page_break()

    # --- PAGE 18 (GAUCHE - VERSO) : DONNÉES BLOC 9 ---
    add_custom_heading(doc, "3. Synthèse synoptique des indicateurs du mémoire", level=1)
    add_custom_heading(doc, "3.1 Tableau récapitulatif des métriques quantitatives", level=2)

    # Tableau 4
    t6_headers = ["Axe", "Dimension", "Indicateur statistique majeur", "Valeur observée"]
    t6_rows = [
        ["Axe A", "Progression globale", "Gain brut moyen (Δ) sur 20 points", "+5,93 à +7,45 pts"],
        ["Axe A", "Amplitude de l'effet", "Taille d'effet de Rosenthal (r)", "r ≈ 0,61 - 0,62"],
        ["Axe A", "Cote de réussite", "Odds Ratio GLM Formation", "OR = 3,94 - 5,54"],
        ["Axe A", "Vitesse d'apprentissage", "Interaction Public × Formation", "p = 0,903 (NS)"],
        ["Axe A", "Doute / Évitement", "Réduction de l'abstention ('Je ne sais pas')", "-85,3 % à -92,2 %"],
        ["Axe A", "Facteurs biologiques", "Interaction Sexe × Formation", "p = 0,393 (NS)"],
        ["Axe B", "Difficulté extrême", "Genre le plus résistant à l'apprentissage", "Stelis (57,4 % err)"],
        ["Axe B", "Confusion majeure", "Paire d'erreur prédominante", "Sphecodes -> Nomada (58,3 %)"],
        ["Axe B", "Maîtrise totale", "Genre le plus facile", "Xylocopa (0,0 % err)"],
    ]
    t6_widths = [Cm(1.8), Cm(3.6), Cm(5.6), Cm(5.4)]
    t6_aligns = [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER]
    add_table_component(
        doc, table_num="4",
        title="Tableau synoptique récapitulatif des indicateurs clés du mémoire",
        description="Synthèse synoptique transversale des principales métriques quantitatives établies pour répondre aux questions de recherche des Axes A et B.",
        headers=t6_headers, data_rows=t6_rows, col_widths=t6_widths, alignments=t6_aligns
    )

    doc.add_page_break()

    # --- PAGE 19 (DROITE - RECTO) : DESCRIPTION BLOC 9 ---
    add_custom_heading(doc, "Description des résultats : Synthèse récapitulative transversale", level=2)

    add_description_paragraph(
        doc,
        "Le Tableau 4 synthétise les principaux indicateurs statistiques et métriques quantitatives mesurés dans ce travail "
        "pour répondre aux objectifs de recherche définis dans les Axes A et B."
    )

    add_description_paragraph(
        doc,
        "Concernant l'Axe A (évaluation de la formation) : "
        "\n• Le gain brut moyen mesuré sur l'échelle de 20 points se situe entre +5,93 et +7,45 points pour les cohortes suivies longitudinalement. "
        "\n• L'amplitude de l'effet, évaluée par le coefficient de corrélation de rang r de Rosenthal, se situe entre r = 0,61 et r = 0,62. "
        "\n• Les Odds Ratios ajustés issus des modèles GLM indiquent une multiplication de la cote de réussite par un facteur compris entre 3,94 et 5,54. "
        "\n• Le terme d'interaction Public × Formation n'est pas significatif (p = 0,903). "
        "\n• La proportion de réponses d'abstention (« Je ne sais pas ») enregistre une réduction relative comprise entre -85,3 % et -92,2 %. "
        "\n• L'interaction Session × Sexe n'est pas statistiquement significative (p = 0,393)."
    )

    add_description_paragraph(
        doc,
        "Concernant l'Axe B (caractérisation taxonomique) : "
        "\n• Le taux d'erreur résiduel moyen le plus élevé après formation est observé chez le genre Stelis (57,4 % d'erreur). "
        "\n• La paire de confusion la plus fréquente parmi les erreurs enregistrées est Sphecodes déterminé comme Nomada, qui représente 58,3 % "
        "des réponses incorrectes sur ce genre. "
        "\n• Le genre présentant le taux d'identification correcte le plus élevé est Xylocopa, avec un taux de réussite de 100,0 % (0,0 % d'erreur)."
    )

    # Sauvegarde des documents Word
    # 1. Sauvegarde sur le fichier commenté (Partie_Resultats_Memoire_Commente.docx)
    try:
        doc.save(fichier_docx_commente)
        taille_ko_c = round(os.path.getsize(fichier_docx_commente) / 1024, 1)
        print(f"--> SUCCÈS : Document sauvegardé sous '{os.path.basename(fichier_docx_commente)}' ({taille_ko_c} Ko) !")
    except PermissionError:
        print(f"--> NOTE : '{os.path.basename(fichier_docx_commente)}' est actuellement verrouillé par Word.")

    # 2. Sauvegarde sur le fichier descriptif (Partie_Resultats_Memoire_Descriptif.docx)
    try:
        doc.save(fichier_docx_descriptif)
        taille_ko = round(os.path.getsize(fichier_docx_descriptif) / 1024, 1)
        print(f"--> SUCCÈS : Document sauvegardé sous '{os.path.basename(fichier_docx_descriptif)}' ({taille_ko} Ko) !")
    except PermissionError:
        print(f"--> NOTE : '{os.path.basename(fichier_docx_descriptif)}' est actuellement ouvert dans Word.")


if __name__ == "__main__":
    main()
