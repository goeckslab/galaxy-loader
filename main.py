import argparse

from bioblend.galaxy import GalaxyInstance
from bioblend.galaxy.libraries import LibraryClient
from bioblend.galaxy.histories import HistoryClient
from bioblend.galaxy.folders import FoldersClient
from datetime import datetime
from time import sleep

parser = argparse.ArgumentParser()

parser.add_argument("-a", "--apikey")
parser.add_argument("-e", "--endpoint")
parser.add_argument("-p", "--port")
parser.add_argument("-s", "--sourcedir")

args = parser.parse_args()

host = "127.0.0.1" if not args.endpoint else args.endpoint
port = "8080"
addr = host + ":{}".format(port) if port else ""

apik = args.apikey

gi = GalaxyInstance(addr, apik)
lc = LibraryClient(gi)
fc = FoldersClient(gi)
hc = HistoryClient(gi)

library_name = "GDC Files"
library_description = "A library of files acquired from the NCI Genomic Data Commons (GDC)"
libs=lc.get_libraries()
lib = {}

if libs and isinstance(libs, dict):
    libs = [libs]
if libs:
    for _lib in libs:
        if "name" in _lib and _lib["name"] == library_name:
            lib = _lib
else:
    lib = lc.create_library(library_name, library_description)
    print("Library {} created:\n{}".format(library_name, lib))

if not lib:
    print("ERROR: no library")
    exit()

print("lib:{}".format(lib))

now_string = datetime.today().strftime("%Y-%m-%d @ %H:%M:%S")

# create folder to live in
folder = fc.create_folder(parent_folder_id=lib["root_folder_id"], name=now_string)
print(folder)
sleep(1)

# NOTE: NOT RECURSIVE -- only files in base dir
def add_files_in_path_to_lib(lib_id, folder_id, path):
    # FORMAT: upload_file_from_server(library_id, server_dir, folder_id=None, file_type='auto', dbkey='?', link_data_only=None, roles='', preserve_dirs=False, tag_using_filenames=False, tags=None)
    return lc.upload_file_from_server(
            library_id = lib_id,
            server_dir = path,
            folder_id = folder_id,
            link_data_only = "link_to_files",
            tag_using_filenames=True
            )

files = add_files_in_path_to_lib(lib["id"], folder["id"], args.sourcedir)
if isinstance(files, dict):
    files = [files]
print(files)
print("Data check on {} files:".format(len(files)))
print("waiting on datasets to become available...")
ready = 0
old_ready = -1
while ready < len(files):
    if ready != old_ready:
        print("ready files: {}".format(ready))
        old_ready = ready
    ready = 0
    for f in fc.show_folder(folder["id"], contents=True)["folder_contents"]:
        if f["state"] == "ok":
            ready = ready + 1
    sleep(5)
print("All {} datasets ready!".format(ready))

# add files to history 
history = hc.create_history("{}".format(now_string))
print(history)

# create dataset collection
collection_description = {
    'collection_type': 'list',
    'element_identifiers': [],
    'name': 'manifest collection'
}
for f in files:
    element_identifier = {
        'id': f["id"],
        'name': f["name"],
        'src': 'ldda'}
    collection_description["element_identifiers"].append(element_identifier)

print(collection_description)

hc.create_dataset_collection(history["id"], collection_description)