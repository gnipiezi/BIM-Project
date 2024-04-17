import ifcopenshell
import re
import pandas as pd
import os

def gen_ifc_file(excel_path, ifc_path, output_folder):
    df_isolants = pd.read_excel(excel_path, usecols=[0], engine='openpyxl')
    df_isolants = df_isolants.dropna()  

    ifc_file = ifcopenshell.open(ifc_path)
    walls = ifc_file.by_type('IfcWall')

    for index, row in df_isolants.head(3).iterrows():
        new_isolant_name = row[df_isolants.columns[0]]

        for wall in walls:
            material_associations = ifc_file.get_inverse(wall, 'ReferencedBy')
            for association in material_associations:
                if association.is_a('IfcRelAssociatesMaterial'):
                    material_definition = association.RelatingMaterial
                    if material_definition.is_a('IfcMaterialLayerSetUsage'):
                        material_layer_set = material_definition.ForLayerSet
                        for material_layer in material_layer_set.MaterialLayers:
                            material_layer.Material.Name = new_isolant_name

        new_ifc_filename = f"{new_isolant_name.replace(' ', '_')}.ifc"
        new_ifc_path = os.path.join(output_folder, new_ifc_filename)
        ifc_file.write(new_ifc_path)
        print(f"Le fichier IFC avec le nouvel isolant '{new_isolant_name}' a été sauvegardé sous : {new_ifc_path}")