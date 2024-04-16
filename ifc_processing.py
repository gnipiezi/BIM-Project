import ifcopenshell
import re
import pandas as pd
import os

output_folder = './output'
pattern_isolant = re.compile(r"laine minérale|EPS|polyuréthane|fibre de verre", re.IGNORECASE)
pattern_materiau = re.compile(r"bois|béton|brique|bloc de béton cellulaire", re.IGNORECASE)

def process_ifc_file(ifc_path):
    ifc_file = ifcopenshell.open(ifc_path)
    walls = ifc_file.by_type('IfcWall')
    materiaux = set()
    isolants = set()

    for wall in walls:
        material_associations = ifc_file.get_inverse(wall, 'ReferencedBy')
        for association in material_associations:
            if association.is_a('IfcRelAssociatesMaterial'):
                material_definition = association.RelatingMaterial
                if material_definition.is_a('IfcMaterialLayerSetUsage'):
                    material_layer_set = material_definition.ForLayerSet
                    for material_layer in material_layer_set.MaterialLayers:
                        material_name = material_layer.Material.Name
                        material_thickness = material_layer.LayerThickness
                        if pattern_isolant.search(material_name):
                            isolants.add((material_name, material_thickness))
                        elif pattern_materiau.search(material_name):
                            materiaux.add((material_name, material_thickness))
                elif material_definition.is_a('IfcMaterial'):
                    material_name = material_definition.Name
                    if pattern_isolant.search(material_name):
                        isolants.add(material_name)
                    elif pattern_materiau.search(material_name):
                        materiaux.add(material_name)

    df_materiaux = pd.DataFrame(list(materiaux), columns=['Matériaux de Construction', 'Épaisseur Matériaux (mm)'])
    df_isolants = pd.DataFrame(list(isolants), columns=['Isolants', 'Épaisseur Isolants (mm)'])
    df_final = pd.concat([df_materiaux, df_isolants], axis=1)
    filename = os.path.join(output_folder, 'materiaux_et_isolants.xlsx')
    df_final.to_excel(filename, index=False)
    print(f"Les matériaux et isolants ont été écrits dans {filename}")
    os.remove(ifc_path)
