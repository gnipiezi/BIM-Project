from watchdog.events import FileSystemEventHandler
from ifc_processing import process_ifc_file
from gen_ifc_file import gen_ifc_file
import os
import time
from config import input_folder, file_to_watch , excel_path ,  output_folder
class IFCFileHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.src_path.endswith('.ifc'):
            print(f"Nouveau fichier IFC détecté : {event.src_path}")
            time.sleep(1)  
            try:
                process_ifc_file(event.src_path)
            except Exception as e:
                print(f"Erreur lors du traitement du fichier IFC : {event.src_path}")
                print(f"Détails de l'erreur : {e}")

class ExcelChangeHandler(FileSystemEventHandler):
    def __init__(self, file_to_watch, input_folder, output_folder):
        self.file_to_watch = file_to_watch
        self.input_folder = input_folder
        self.output_folder = output_folder

    def find_first_ifc(self):
        for file in os.listdir(self.input_folder):
            if file.lower().endswith('.ifc'):
                return os.path.join(self.input_folder, file)
        return None  

    def on_modified(self, event):
        if os.path.abspath(event.src_path) == self.file_to_watch:
            print("Le fichier Excel a été modifié. Lecture des données...")
            ifc_path = self.find_first_ifc()
            if ifc_path is not None:
                try:
                    gen_ifc_file(self.file_to_watch, ifc_path, self.output_folder)
                    print("Traitement du fichier IFC terminé avec succès.")
                    
                except Exception as e:
                    print(f"Erreur lors du traitement du fichier IFC : {e}")
            else:
                print("Aucun fichier IFC trouvé dans le dossier spécifié.")


