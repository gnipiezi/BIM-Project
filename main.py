from watchdog.observers import Observer
from watchdog_handlers import IFCFileHandler, ExcelChangeHandler
import os
import time
import pandas as pd
from config import input_folder, file_to_watch
import subprocess
folder_path = os.path.dirname(file_to_watch)

event_handler = ExcelChangeHandler(file_to_watch)
observer = Observer()
observer.schedule(event_handler, folder_path, recursive=False)

observer1 = Observer()
observer1.schedule(IFCFileHandler(), path=input_folder, recursive=False)

observer.start()
observer1.start()

print(f"Surveillance du fichier : {file_to_watch}")
command = 'Rscript'
path_to_r_script = './app.R'
subprocess.Popen([command, path_to_r_script])
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    observer.stop()
    observer1.stop()
