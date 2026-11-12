#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
==============================================================================
Générateur Python du Document Word des Résultats du Mémoire (UMons)
Auteur : Analyse de données & Mémoire de Fin d'Études
Objectif : Importer les graphiques HD, tableaux formatés et descriptions
           sans blocs d'analyse narrative, avec une mise en page soignée.
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
COLOR_NAVY_HEX = "1B365D"       # Bleu nuit (Titres, en-têtes)
COLOR_SLATE_HEX = "4A90E2"      # Bleu ardoise
COLOR_LIGHT_BG_HEX = "F4F6F8"   # Fond zébré doux
COLOR_BORDER_HEX = "D0D7DE"     # Bordures subtiles
COLOR_WHITE_HEX = "FFFFFF"

COLOR_NAVY_RGB = RGBColor(27, 54, 93)
COLOR_GREY_RGB = RGBColor(85, 95, 110)
COLOR_BLACK_RGB = RGBColor(30, 30, 30)


def configure_page_margins(doc):
    """Configure des marges A4 équilibrées de 2,3 cm pour optimiser l'espace."""
    for section in doc.sections:
        section.top_margin = Cm(2.3)
        section.bottom_margin = Cm(2.3)
        section.left_margin = Cm(2.3)
        section.right_margin = Cm(2.3)
        section.page_width = Cm(21.0)
        section.page_height = Cm(29.7)


def set_cell_background(cell, hex_color):
    """Applique une couleur d'arrière-plan à une cellule."""
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    tcPr.append(shd)


def set_cell_margins(cell, top=90, bottom=90, left=130, right=130):
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

    # Bordures horizontales de style académique (pas de bordures verticales)
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

    # Répéter l'en-tête sur chaque page
    header_trPr = table.rows[0]._tr.get_or_add_trPr()
    header_trPr.append(parse_xml(f'<w:tblHeader {nsdecls("w")}/>'))

    # Interdire la coupure des lignes à travers les sauts de page
    for row in table.rows:
        trPr = row._tr.get_or_add_trPr()
        trPr.append(parse_xml(f'<w:cantSplit {nsdecls("w")}/>'))

    # Appliquer les largeurs strictes à chaque cellule
    for row in table.rows:
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
        p.paragraph_format.space_before = Pt(18)
        p.paragraph_format.space_after = Pt(6)
        run.font.size = Pt(16)
        run.font.color.rgb = COLOR_NAVY_RGB
    elif level == 2:
        p.paragraph_format.space_before = Pt(14)
        p.paragraph_format.space_after = Pt(4)
        run.font.size = Pt(13)
        run.font.color.rgb = COLOR_NAVY_RGB
    elif level == 3:
        p.paragraph_format.space_before = Pt(10)
        p.paragraph_format.space_after = Pt(3)
        run.font.size = Pt(11.5)
        run.font.color.rgb = RGBColor(41, 128, 185)


def add_table_component(doc, table_num, title, description, headers, data_rows, col_widths, alignments=None):
    """Insère un tableau formaté, compact et accompagné de sa description descriptive."""
    if alignments is None:
        alignments = [WD_ALIGN_PARAGRAPH.LEFT] * len(headers)

    # Titre du tableau
    p_title = doc.add_paragraph()
    p_title.paragraph_format.space_before = Pt(10)
    p_title.paragraph_format.space_after = Pt(2)
    p_title.paragraph_format.keep_with_next = True
    r_tag = p_title.add_run(f"Tableau {table_num} : ")
    r_tag.bold = True
    r_tag.font.name = "Calibri"
    r_tag.font.size = Pt(10.5)
    r_tag.font.color.rgb = COLOR_NAVY_RGB

    r_tit = p_title.add_run(title)
    r_tit.bold = True
    r_tit.font.name = "Calibri"
    r_tit.font.size = Pt(10.5)
    r_tit.font.color.rgb = COLOR_BLACK_RGB

    # Description du tableau
    p_desc = doc.add_paragraph()
    p_desc.paragraph_format.space_before = Pt(0)
    p_desc.paragraph_format.space_after = Pt(6)
    p_desc.paragraph_format.keep_with_next = True
    r_desc = p_desc.add_run(description)
    r_desc.italic = True
    r_desc.font.name = "Calibri"
    r_desc.font.size = Pt(9.5)
    r_desc.font.color.rgb = COLOR_GREY_RGB

    # Création du tableau Word
    table = doc.add_table(rows=len(data_rows) + 1, cols=len(headers))
    set_table_styling(table, col_widths)

    # Remplissage de l'en-tête
    hdr_cells = table.rows[0].cells
    for i, h_text in enumerate(headers):
        cell = hdr_cells[i]
        cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        set_cell_background(cell, COLOR_NAVY_HEX)
        set_cell_margins(cell, top=100, bottom=100, left=120, right=120)
        p = cell.paragraphs[0]
        p.alignment = alignments[i]
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        p.paragraph_format.line_spacing = 1.0
        run = p.add_run(h_text)
        run.bold = True
        run.font.name = "Calibri"
        run.font.size = Pt(9.5)
        run.font.color.rgb = RGBColor(255, 255, 255)

    # Remplissage des lignes de données
    for r_idx, row_data in enumerate(data_rows):
        row_cells = table.rows[r_idx + 1].cells
        bg_col = COLOR_LIGHT_BG_HEX if (r_idx % 2 == 1) else COLOR_WHITE_HEX
        for c_idx, cell_value in enumerate(row_data):
            cell = row_cells[c_idx]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            set_cell_background(cell, bg_col)
            set_cell_margins(cell, top=70, bottom=70, left=110, right=110)
            p = cell.paragraphs[0]
            p.alignment = alignments[c_idx]
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.line_spacing = 1.05
            run = p.add_run(str(cell_value))
            run.font.name = "Calibri"
            run.font.size = Pt(9.0)
            run.font.color.rgb = COLOR_BLACK_RGB

    doc.add_paragraph().paragraph_format.space_after = Pt(4)


def add_figure_component(doc, figure_num, title, description, image_path, width_cm=16.0):
    """Insère une figure centrée haute définition accompagnée de sa légende descriptive."""
    if not os.path.exists(image_path):
        print(f"[ATTENTION] Image introuvable : {image_path}")
        return

    # Paragraphe de l'image centrée
    p_img = doc.add_paragraph()
    p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_img.paragraph_format.space_before = Pt(8)
    p_img.paragraph_format.space_after = Pt(4)
    p_img.paragraph_format.keep_with_next = True
    run_img = p_img.add_run()
    run_img.add_picture(image_path, width=Cm(width_cm))

    # Légende descriptive sous la figure
    p_leg = doc.add_paragraph()
    p_leg.paragraph_format.space_before = Pt(2)
    p_leg.paragraph_format.space_after = Pt(12)
    p_leg.paragraph_format.line_spacing = 1.15

    r_num = p_leg.add_run(f"Figure {figure_num} : ")
    r_num.bold = True
    r_num.font.name = "Calibri"
    r_num.font.size = Pt(9.5)
    r_num.font.color.rgb = COLOR_NAVY_RGB

    r_tit = p_leg.add_run(f"{title}. ")
    r_tit.bold = True
    r_tit.font.name = "Calibri"
    r_tit.font.size = Pt(9.5)
    r_tit.font.color.rgb = COLOR_BLACK_RGB

    r_desc = p_leg.add_run(description)
    r_desc.italic = True
    r_desc.font.name = "Calibri"
    r_desc.font.size = Pt(9.0)
    r_desc.font.color.rgb = COLOR_GREY_RGB


def main():
    print("--> Lancement de la génération du document Word des Résultats via Python...")

    dossier_base = os.path.dirname(os.path.abspath(__file__))
    dossier_figures = os.path.join(dossier_base, "figures")
    fichier_docx_sortie = os.path.join(dossier_base, "Partie_Resultats_Memoire.docx")

    doc = Document()
    configure_page_margins(doc)

    # =========================================================================
    # EN-TÊTE DU DOCUMENT
    # =========================================================================
    p_main = doc.add_paragraph()
    p_main.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_main.paragraph_format.space_before = Pt(6)
    p_main.paragraph_format.space_after = Pt(2)
    r_main = p_main.add_run("RÉSULTATS DU MÉMOIRE DE FIN D'ÉTUDES")
    r_main.bold = True
    r_main.font.name = "Calibri"
    r_main.font.size = Pt(18)
    r_main.font.color.rgb = COLOR_NAVY_RGB

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_sub.paragraph_format.space_before = Pt(0)
    p_sub.paragraph_format.space_after = Pt(2)
    r_sub = p_sub.add_run("Évaluation de l'apprentissage taxonomique de l'identification des abeilles sauvages (Hymenoptera : Apoidea)")
    r_sub.font.name = "Calibri"
    r_sub.font.size = Pt(12)
    r_sub.font.color.rgb = COLOR_BLACK_RGB

    p_fil = doc.add_paragraph()
    p_fil.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_fil.paragraph_format.space_before = Pt(0)
    p_fil.paragraph_format.space_after = Pt(16)
    r_fil = p_fil.add_run("Recueil ordonné des visualisations scientifiques, tableaux adaptés et descriptions méthodologiques")
    r_fil.italic = True
    r_fil.font.name = "Calibri"
    r_fil.font.size = Pt(10.5)
    r_fil.font.color.rgb = COLOR_GREY_RGB

    # =========================================================================
    # SECTION 1 : ÉCHANTILLONNAGE ET QUALITÉ DES DONNÉES
    # =========================================================================
    add_custom_heading(doc, "1. Échantillonnage, attrition et qualité des données", level=1)

    # Tableau 1
    t1_headers = ["Cohorte", "Profil du public", "Design expérimental", "N init.", "N analysé", "Rétention", "Items"]
    t1_rows = [
        ["EPIC 2025", "Adultes naturalistes", "Longitudinal (Pré vs Post)", "56", "50 Pré / 49 Post", "87,5 %", "30"],
        ["BAC 3 (2024)", "Étudiants Biologie", "Longitudinal apparié", "32", "25 paires", "78,1 %", "26"],
        ["BAC 3 (2025)", "Étudiants Biologie", "Longitudinal apparié", "23", "22 paires", "95,7 %", "28"],
        ["EPIC (2026)", "Adultes naturalistes", "Transversal (Formés vs Témoins)", "172", "64 Formés / 108 Témoins", "100,0 %", "30"],
    ]
    t1_widths = [Cm(2.6), Cm(3.2), Cm(3.6), Cm(1.6), Cm(2.3), Cm(1.6), Cm(1.3)]
    t1_aligns = [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT,
                 WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER]
    add_table_component(
        doc, table_num=1,
        title="Traçabilité de l'échantillonnage, attrition et structure des épreuves",
        description="Synthèse des effectifs initiaux, des exclusions motivées (doublons, abandons précoces et durées aberrantes < 180 s) et des effectifs finaux analysés pour chaque cohorte.",
        headers=t1_headers, data_rows=t1_rows, col_widths=t1_widths, alignments=t1_aligns
    )

    # Figure 1
    add_figure_component(
        doc, figure_num=1,
        title="Diagnostic d'intégrité des données, profilage des durées et complétude",
        description="Profilage de la qualité des données individuelles. (A) Distribution des durées de réponse (en minutes) suivant une allure log-normale avec mise en évidence du seuil de speed-run. (B) Complétude globale atteignant > 98,5 % d'items complétés post-nettoyage.",
        image_path=os.path.join(dossier_figures, "fig1_diagnostic_qualite.png"),
        width_cm=15.5
    )

    # =========================================================================
    # SECTION 2 : AXE A — ÉVALUATION ET DYNAMIQUE DE L'APPRENTISSAGE
    # =========================================================================
    add_custom_heading(doc, "2. Axe A — Évaluation et dynamique de l'apprentissage taxonomique", level=1)

    add_custom_heading(doc, "2.1 Trajectoires globales et tailles d'effet", level=2)

    # Tableau 2A
    t2a_headers = ["Cohorte & Année", "Échantillon analysé", "Score Pré (Moy ± ET)", "Score Post (Moy ± ET)", "Gain brut (Δ)", "Gain relatif"]
    t2a_rows = [
        ["EPIC 2025 (Adultes)", "50 Pré / 49 Post", "10,51 ± 4,69", "16,53 ± 2,22", "+6,02 pts", "+30,1 %"],
        ["BAC 3 (2024) (Étudiants)", "25 paires strictes", "6,61 ± 3,21", "14,06 ± 2,76", "+7,45 pts", "+37,2 %"],
        ["BAC 3 (2025) (Étudiants)", "22 paires strictes", "9,33 ± 4,33", "15,26 ± 2,64", "+5,93 pts", "+29,7 %"],
        ["EPIC 2026 (Transversal)", "64 Formés / 108 Témoins", "15,91 ± 3,43", "16,53 ± 2,77", "+0,62 pt", "+3,1 %"],
    ]
    t2a_widths = [Cm(3.3), Cm(3.1), Cm(2.6), Cm(2.6), Cm(2.3), Cm(2.3)]
    t2a_aligns = [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER,
                  WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER]
    add_table_component(
        doc, table_num="2A",
        title="Performances descriptives Pré vs Post et gains observés (sur 20 points)",
        description="Moyennes et écarts-types des scores standardisés sur 20 points, accompagnés des gains absolus et pourcentages d'amélioration observés dans les différentes cohortes.",
        headers=t2a_headers, data_rows=t2a_rows, col_widths=t2a_widths, alignments=t2a_aligns
    )

    # Tableau 2B
    t2b_headers = ["Cohorte & Année", "Test inférentiel", "Valeur p", "d de Cohen", "r de Rosenthal", "Odds Ratio ajusté [IC 95 %]"]
    t2b_rows = [
        ["EPIC 2025", "Wilcoxon Mann-Whitney (W = 2103)", "< 0,001", "1,64", "0,62", "3,94 [2,74 - 5,66]"],
        ["BAC 3 (2024)", "Wilcoxon apparié (V = 325)", "< 0,001", "2,73", "0,62", "5,54 [3,77 - 8,14]"],
        ["BAC 3 (2025)", "Wilcoxon apparié (V = 252)", "< 0,001", "1,40", "0,61", "4,37 [2,73 - 6,98]"],
        ["EPIC 2026", "GLM multivarié (t = -2,02)", "0,046", "0,19", "0,07", "1,42 [1,01 - 2,01]"],
    ]
    t2b_widths = [Cm(2.6), Cm(4.4), Cm(1.8), Cm(1.8), Cm(1.8), Cm(3.8)]
    t2b_aligns = [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER,
                  WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER]
    add_table_component(
        doc, table_num="2B",
        title="Tests statistiques inférentiels et tailles d'effet de l'apprentissage",
        description="Tests d'hypothèses univariés et multivariés, tailles d'effet de Cohen (d) et Rosenthal (r), et Odds Ratios ajustés pour le temps de passation.",
        headers=t2b_headers, data_rows=t2b_rows, col_widths=t2b_widths, alignments=t2b_aligns
    )

    # Figure 2
    add_figure_component(
        doc, figure_num=2,
        title="Trajectoires d'évolution des scores Pré vs Post à travers les cohortes",
        description="Évolution des scores moyens et distributions individuelles (sur 20 points) entre pré-test et post-test. Les barres d'erreur représentent l'intervalle de confiance à 95 % de la moyenne. Les trois cohortes longitudinales affichent un bond homogène de +6 à +7,5 points.",
        image_path=os.path.join(dossier_figures, "fig2_trajectoires_intercohortes.png"),
        width_cm=16.0
    )

    # Figure 3
    add_figure_component(
        doc, figure_num=3,
        title="Forest Plot des tailles d'effet de l'apprentissage taxonomique",
        description="Représentation comparée des tailles d'effet. À gauche : indice d de Cohen (d > 0,80 indique un effet fort, culminant à 1,40 - 2,73). À droite : Odds Ratios ajustés et leurs intervalles de confiance à 95 % issus des modélisations GLM multivariées.",
        image_path=os.path.join(dossier_figures, "fig3_forest_plot_tailles_effet.png"),
        width_cm=15.5
    )

    add_custom_heading(doc, "2.2 Distribution des scores et déblocage de l'inhibition", level=2)

    # Figure 4
    add_figure_component(
        doc, figure_num=4,
        title="Distributions et densités des scores avant et après formation",
        description="Densités des scores avant (rouge) et après (vert) apprentissage (cohorte EPIC 2025). Illustration de l'effet plafond post-formation (Shapiro-Wilk p < 0,01) et du resserrement massif de la dispersion (variance divisée par plus de 4, Fligner-Killeen p < 0,001).",
        image_path=os.path.join(dossier_figures, "fig4_distributions_scores.png"),
        width_cm=15.5
    )

    # Figure 5
    add_figure_component(
        doc, figure_num=5,
        title="Effondrement de l'abstention et des réponses « Je ne sais pas »",
        description="Proportion d'items avec réponse d'évitement ou d'abstention avant et après apprentissage. Chute universelle de l'incertitude comprise entre -85,3 % et -92,2 % à travers toutes les cohortes suivies longitudinalement.",
        image_path=os.path.join(dossier_figures, "fig5_effondrement_idk.png"),
        width_cm=15.5
    )

    add_custom_heading(doc, "2.3 Variables médiatrices et facteurs biologiques", level=2)

    # Figure 6
    add_figure_component(
        doc, figure_num=6,
        title="Relation entre la durée totale de passation et la performance",
        description="Régression entre temps de complétion (minutes) et score final. En post-test, un temps de réponse prolongé traduit des hésitations sur les genres morphologiquement ambigus et s'associe à un score inférieur (beta = -0,0094, p = 0,0018).",
        image_path=os.path.join(dossier_figures, "fig6_duree_vs_performance.png"),
        width_cm=15.5
    )

    # Figure 7
    add_figure_component(
        doc, figure_num=7,
        title="Taux de succès selon le sexe du spécimen et la guilde écologique",
        description="Taux d'identification correcte selon le sexe (mâles vs femelles) et la guilde (pollinisateurs non-parasites vs cléptoparasites coucous). Absence d'interaction Formation x Sexe (p = 0,393) et gain plus marqué sur les coucous (+37,1 % vs +27,6 %).",
        image_path=os.path.join(dossier_figures, "fig7_facteurs_biologiques_sexe_guilde.png"),
        width_cm=15.5
    )

    add_custom_heading(doc, "2.4 Modélisation comparative inter-cohortes (Interaction Public × Formation)", level=2)

    # Tableau 3
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
        doc, table_num=3,
        title="Modèle Linéaire Généralisé Quasibinomial testant l'interaction Public × Formation",
        description="Coefficients de régression logistique quasibinomiale (N = 5 160 déterminations). L'absence d'interaction significative (p = 0,903) confirme que les adultes et les étudiants progressent avec la même intensité.",
        headers=t3_headers, data_rows=t3_rows, col_widths=t3_widths, alignments=t3_aligns
    )

    # =========================================================================
    # SECTION 3 : AXE B — IDENTIFICATION DES GENRES PIÈGES ET CONFUSIONS
    # =========================================================================
    add_custom_heading(doc, "3. Axe B — Identification des genres pièges et analyse des confusions", level=1)

    add_custom_heading(doc, "3.1 Gradient consensuel de difficulté des 27 genres", level=2)

    # Tableau 4 (27 genres)
    t4_headers = ["Catégorie", "Genre", "Famille", "Guilde", "Taux de succès", "Taux d'erreur [IC 95 % Wilson]"]
    t4_rows = [
        # Très difficile
        ["Très difficile (≥ 35 %)", "Stelis", "Megachilidae", "Cléptoparasite", "42,6 %", "57,4 % [43,3 - 70,5 %]"],
        ["", "Trachusa", "Megachilidae", "Non parasite", "45,5 %", "54,5 % [34,7 - 73,1 %]"],
        ["", "Anthophora", "Apidae", "Non parasite", "46,9 %", "53,1 % [43,2 - 62,8 %]"],
        ["", "Lasioglossum", "Halictidae", "Non parasite", "54,2 %", "45,8 % [37,0 - 54,7 %]"],
        ["", "Megachile", "Megachilidae", "Non parasite", "57,0 %", "43,0 % [34,5 - 51,9 %]"],
        ["", "Sphecodes", "Halictidae", "Cléptoparasite", "57,8 %", "42,2 % [35,4 - 49,3 %]"],
        ["", "Chelostoma", "Megachilidae", "Non parasite", "61,2 %", "38,8 % [26,4 - 52,8 %]"],
        # Difficulté modérée
        ["Difficulté modérée (20-34 %)", "Andrena", "Andrenidae", "Non parasite", "69,8 %", "30,2 % [24,2 - 37,0 %]"],
        ["", "Osmia", "Megachilidae", "Non parasite", "71,9 %", "28,1 % [20,1 - 37,8 %]"],
        ["", "Ammobates", "Apidae", "Cléptoparasite", "73,5 %", "26,5 % [16,2 - 40,3 %]"],
        ["", "Eucera", "Apidae", "Non parasite", "78,0 %", "22,0 % [15,5 - 30,3 %]"],
        ["", "Hoplitis", "Megachilidae", "Non parasite", "79,6 %", "20,4 % [11,5 - 33,6 %]"],
        ["", "Melecta", "Apidae", "Cléptoparasite", "79,6 %", "20,4 % [11,5 - 33,6 %]"],
        # Accessible
        ["Accessible (10-19 %)", "Nomada", "Apidae", "Cléptoparasite", "81,2 %", "18,8 % [13,9 - 24,9 %]"],
        ["", "Epeolus", "Apidae", "Cléptoparasite", "81,6 %", "18,4 % [10,0 - 31,4 %]"],
        ["", "Panurgus", "Andrenidae", "Non parasite", "82,3 %", "17,7 % [11,4 - 26,5 %]"],
        ["", "Anthidium", "Megachilidae", "Non parasite", "85,4 %", "14,6 % [8,9 - 23,0 %]"],
        ["", "Colletes", "Colletidae", "Non parasite", "85,4 %", "14,6 % [8,9 - 23,0 %]"],
        ["", "Ceratina", "Apidae", "Non parasite", "88,5 %", "11,5 % [6,5 - 19,4 %]"],
        ["", "Macropis", "Melittidae", "Non parasite", "89,8 %", "10,2 % [4,4 - 21,8 %]"],
        # Facile
        ["Facile (< 10 %)", "Coelioxys", "Megachilidae", "Cléptoparasite", "91,8 %", "8,2 % [3,2 - 19,2 %]"],
        ["", "Halictus", "Halictidae", "Non parasite", "92,4 %", "7,6 % [4,1 - 13,9 %]"],
        ["", "Hylaeus", "Colletidae", "Non parasite", "92,7 %", "7,3 % [4,4 - 11,9 %]"],
        ["", "Bombus", "Apidae", "Non parasite", "94,0 %", "6,0 % [3,5 - 10,0 %]"],
        ["", "Apis", "Apidae", "Non parasite", "95,8 %", "4,2 % [1,6 - 10,2 %]"],
        ["", "Dasypoda", "Melittidae", "Non parasite", "95,8 %", "4,2 % [1,6 - 10,2 %]"],
        ["", "Xylocopa", "Apidae", "Non parasite", "100,0 %", "0,0 % [0,0 - 3,8 %]"],
    ]
    t4_widths = [Cm(3.5), Cm(2.5), Cm(2.7), Cm(2.5), Cm(2.2), Cm(2.8)]
    t4_aligns = [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT,
                 WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER]
    add_table_component(
        doc, table_num=4,
        title="Gradient consensuel de difficulté taxonomique des 27 genres (Post-formation)",
        description="Classification structurée en 4 niveaux selon le taux d'erreur moyen post-formation et ses intervalles de confiance de Wilson à 95 % calculés sur l'ensemble des cohortes.",
        headers=t4_headers, data_rows=t4_rows, col_widths=t4_widths, alignments=t4_aligns
    )

    # Figure 8
    add_figure_component(
        doc, figure_num=8,
        title="Gradient de difficulté taxonomique consensuel des 27 genres d'abeilles sauvages",
        description="Taux d'erreur moyen résiduel post-formation par genre d'abeille avec intervalles de confiance de Wilson à 95 %. Les couleurs illustrent les quatre paliers d'assimilation cognitive du mémoire.",
        image_path=os.path.join(dossier_figures, "fig8_consensus_difficulte_genres.png"),
        width_cm=16.0
    )

    add_custom_heading(doc, "3.2 Modélisation logistique et gains spécifiques", level=2)

    # Figure 9
    add_figure_component(
        doc, figure_num=9,
        title="Forest Plot des Odds Ratios de difficulté par genre (vs Bombus)",
        description="Odds Ratios issus de la régression logistique multivariée prenant le genre Bombus comme niveau de référence universel (OR = 1,00). Les genres pièges présentent des cotes de réussite effondrées (p < 0,001).",
        image_path=os.path.join(dossier_figures, "fig9_forest_plot_or_genres.png"),
        width_cm=16.0
    )

    # Figure 10
    add_figure_component(
        doc, figure_num=10,
        title="Volcano Plot des gains d'apprentissage par genre d'abeille",
        description="Gain absolu de réussite (Post - Pré) versus niveau de significativité statistique (-log10 de la p-value ajustée de Fisher avec correction FDR). Les genres en vert constituent les cibles d'un apprentissage hautement significatif.",
        image_path=os.path.join(dossier_figures, "fig10_volcano_gains_genres.png"),
        width_cm=15.5
    )

    add_custom_heading(doc, "3.3 Matrice et patrons des confusions taxonomiques", level=2)

    # Figure 11
    add_figure_component(
        doc, figure_num=11,
        title="Matrice de confusion taxonomique globale post-formation",
        description="Distribution des réponses fournies par les apprenants (colonnes) pour chaque spécimen réel testé (lignes). La diagonale représente les identifications correctes ; les cases hors diagonale mettent en évidence les confusions récurrentes.",
        image_path=os.path.join(dossier_figures, "fig11_matrice_confusions.png"),
        width_cm=15.5
    )

    # Figure 12
    add_figure_component(
        doc, figure_num=12,
        title="Principales paires de confusions taxonomiques enregistrées",
        description="Fréquence relative des paires d'erreurs dominantes observées lors des épreuves d'identification.",
        image_path=os.path.join(dossier_figures, "fig12_top_confusions_taxonomiques.png"),
        width_cm=15.5
    )

    # Tableau 5
    t5_headers = ["Confusion observée", "Part des erreurs", "Familles", "Critère morphologique discriminant clé"]
    t5_rows = [
        ["Sphecodes -> Nomada", "58,3 %", "Halictidae -> Apidae", "Abdomen rouge et corps noir glabre ; nervure basale coudée chez Sphecodes."],
        ["Anthophora -> Bombus", "44,1 %", "Apidae -> Apidae", "Habitus trapu et toison dense ; corbicula à corbeille chez Bombus vs scopa velue chez Anthophora."],
        ["Lasioglossum -> Halictus", "36,7 %", "Halictidae -> Halictidae", "Taille et habitus proches ; soies abdominales basales (Lasioglossum) vs apicales (Halictus)."],
        ["Megachile -> Osmia", "31,2 %", "Megachilidae -> Megachilidae", "Brosse ventrale commune ; cuticule sombre (Megachile) vs reflets métalliques (Osmia)."],
        ["Stelis -> Anthidium", "28,9 %", "Megachilidae -> Megachilidae", "Macules jaunes sur fond noir ; absence totale de brosse ventrale chez Stelis (cléptoparasite)."],
    ]
    t5_widths = [Cm(3.4), Cm(2.0), Cm(3.2), Cm(7.6)]
    t5_aligns = [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT]
    add_table_component(
        doc, table_num=5,
        title="Principales confusions taxonomiques et critères morphologiques discriminants",
        description="Caractérisation des cinq paires d'erreurs dominantes, part relative dans les erreurs du taxon cible et critères anatomiques sous-jacents expliquant le piège visuel.",
        headers=t5_headers, data_rows=t5_rows, col_widths=t5_widths, alignments=t5_aligns
    )

    # =========================================================================
    # SECTION 4 : SYNTHÈSE SYNOPTIQUE
    # =========================================================================
    add_custom_heading(doc, "4. Synthèse synoptique des indicateurs du mémoire", level=1)

    # Tableau 6
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
    t6_widths = [Cm(1.8), Cm(3.5), Cm(5.4), Cm(5.5)]
    t6_aligns = [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER]
    add_table_component(
        doc, table_num=6,
        title="Tableau synoptique récapitulatif des indicateurs clés du mémoire",
        description="Synthèse synoptique transversale des principales métriques quantitatives établies pour répondre aux questions de recherche des Axes A et B.",
        headers=t6_headers, data_rows=t6_rows, col_widths=t6_widths, alignments=t6_aligns
    )

    # Sauvegarde du document Word
    doc.save(fichier_docx_sortie)
    taille_ko = round(os.path.getsize(fichier_docx_sortie) / 1024, 1)
    print(f"--> SUCCÈS : Document Word généré avec succès en Python !")
    print(f"--> Fichier : {fichier_docx_sortie}")
    print(f"--> Taille : {taille_ko} Ko")


if __name__ == "__main__":
    main()

