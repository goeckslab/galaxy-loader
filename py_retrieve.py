import argparse
import csv
import os

from gen3.auth import Gen3Auth
from gen3.file import Gen3File


parser = argparse.ArgumentParser()

parser.add_argument("-c", "--credentials", required=True)
parser.add_argument("-e", "--endpoint")
parser.add_argument("-m", "--manifest", required=True)

args = parser.parse_args()

endpoint = "https://nci-crdc.datacommons.io/"

if "endpoint" in args and args.endpoint:
    endpoint = args.endpoint

print(endpoint)
# extract guids from manifest
ids = []
with open(args.manifest, newline='') as csvfile:
    reader = csv.DictReader(csvfile, delimiter="\t")
    for row in reader:
        ids.append(row['id'])
print(ids)

authclient = Gen3Auth(endpoint, refresh_file=args.credentials)
fileclient = Gen3File(endpoint, authclient)

presigned = []

for _id in ids:
    presigned.append(fileclient.get_presigned_url(_id, protocol="https"))

print(presigned)
