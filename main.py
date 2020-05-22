import argparse

from bioblend.galaxy import GalaxyInstance
from bioblend.galaxy.libraries import LibraryClient
from bioblend.galaxy.histories import HistoryClient
from bioblend.galaxy.folders import FoldersClient

from datetime import datetime


parser = argparse.ArgumentParser()

parser.add_argument("-a", "--apikey")
parser.add_argument("-e", "--endpoint")
parser.add_argument("-p", "--port")
parser.add_argument("-s", "--sourcedir")

args = parser.parse_args()

host = "127.0.0.1" if not args.endpoint else args.endpoint
port = "8080"
addr = host + ":{}".format(port) if port else ""

apik = "3217c67d843a7aa0ce3e72497a5ffb00"

gi = GalaxyInstance(addr, apik)
lc = LibraryClient(gi)
fc = FoldersClient(gi)

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

# NOTE: NOT RECURSIVE -- only files in base dir
def add_files_in_path_to_lib(lib_id, folder_id, path):
    # FORMAT: upload_file_from_server(library_id, server_dir, folder_id=None, file_type='auto', dbkey='?', link_data_only=None, roles='', preserve_dirs=False, tag_using_filenames=False, tags=None)
    lc.upload_file_from_server(
            library_id = lib_id,
            server_dir = path,
            folder_id = folder_id,
            link_data_only = "link_to_files",
            tag_using_filenames=True
            )

print(add_files_in_path_to_lib(lib["id"], folder["id"], args.sourcedir))
# add files to history 
