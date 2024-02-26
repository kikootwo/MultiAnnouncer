# .github/scripts/generate_toc_versions.py
import json

def update_toc_interface(flavor, interface_version):
    with open('MultiAnnouncer.toc', 'r') as file:
        lines = file.readlines()

    with open(f"MultiAnnouncer_{flavor}.toc", 'w') as file:
        for line in lines:
            if line.startswith("## Interface:"):
                file.write(f"## Interface: {interface_version}\n")
            else:
                file.write(line)

def generate_toc_files():
    with open('.github/versions.json', 'r') as file:
        versions = json.load(file)["versions"]

    # Map 'classic' to 'Vanilla' for file naming
    flavor_map = {
        "mainline": "Mainline",
        "wrath": "Wrath",
        "classic": "Vanilla"
    }

    for key, version in versions.items():
        flavor = flavor_map[key]
        update_toc_interface(flavor, version)

if __name__ == "__main__":
    generate_toc_files()
