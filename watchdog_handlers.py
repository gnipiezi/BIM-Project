from watchdog.events import FileSystemEventHandler
from ifc_processing import process_ifc_file
import os
import time
from config import input_folder, file_to_watch

class IFCFileHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.src_path.endswith('.ifc'):
            print(f"Nouveau fichier IFC détecté : {event.src_path}")
            time.sleep(1)
            process_ifc_file(event.src_path)

class ExcelChangeHandler(FileSystemEventHandler):
    def __init__(self, file_to_watch):
        self.file_to_watch = file_to_watch

    def on_modified(self, event):
        if os.path.abspath(event.src_path) == self.file_to_watch:
            print("Le fichier Excel a été modifié. Lecture des données...")
            df = pd.read_excel(event.src_path)
            handle_excel_data(event.src_path)

def handle_excel_data(excel_path):
    # Gérer les données Excel
    pass
