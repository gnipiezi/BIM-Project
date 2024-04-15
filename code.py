import ifcopenshell
import re
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import pandas as pd
import time
import os
import subprocess
import logging

excel_path = os.path.abspath("isolants.xlsx")
input_folder = './inputs'  # Dossier à surveiller
output_folder = './output'  # Dossier de sortie

logging.basicConfig(level=logging.INFO)
command = 'Rscript'
path_to_r_script = './app.R'

if not os.path.exists(output_folder):
    os.makedirs(output_folder)

pattern_isolant = re.compile(r"laine minérale|EPS|polyuréthane|fibre de verre", re.IGNORECASE)
pattern_materiau = re.compile(r"bois|béton|brique|bloc de béton cellulaire", re.IGNORECASE)
i = 0

def process_ifc_file(ifc_path ):
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

    # Supprimer 
    os.remove(ifc_path)




subprocess.Popen([command, path_to_r_script])

file_to_watch = os.path.abspath("isolants.xlsx")

class IFCFileHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.src_path.endswith('.ifc'):
            print(f"Nouveau fichier IFC détecté : {event.src_path}")
            time.sleep(1)
            process_ifc_file(event.src_path)

observer1 = Observer()
observer1.schedule(IFCFileHandler(), path=input_folder, recursive=False)
observer1.start()
class ExcelChangeHandler(FileSystemEventHandler):
    def on_modified(self, event):
        ifc_path = "./Panneau MYRAL M32.ifc"
        if os.path.abspath(event.src_path) == file_to_watch:
            print("Le fichier Excel a été modifié. Lecture des données...")
            df = pd.read_excel(event.src_path)
            handle_excel_data(excel_path, ifc_path, output_folder)

def handle_excel_data(excel_path, ifc_path, output_folder):
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

# process_ifc_file()

folder_path = os.path.dirname(file_to_watch)  
event_handler = ExcelChangeHandler()
observer = Observer()
observer.schedule(event_handler, folder_path, recursive=False)
observer.start()

print(f"Surveillance du fichier : {file_to_watch}")

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    observer.stop() 