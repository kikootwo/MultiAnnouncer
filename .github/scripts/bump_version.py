# .github/scripts/bump_version.py
import re
import sys

def bump_version(version_type, toc_file_path='MultiAnnouncer.toc'):
    # Read the .toc file
    with open(toc_file_path, 'r') as file:
        content = file.read()

    # Find the version line
    version_line = re.search(r'^## Version: (\d+)\.(\d+)\.(\d+)$', content, re.M)
    if not version_line:
        raise ValueError("Version line not found in TOC file.")

    major, minor, patch = map(int, version_line.groups())

    # Treat 'auto' as a 'minor' bump
    if version_type == 'auto' or version_type == 'minor':
        minor += 1
        patch = 0  # Reset patch version on minor bump
    elif version_type == 'major':
        major += 1
        minor = 0  # Reset minor version on major bump
        patch = 0  # Reset patch version on major bump
    elif version_type == 'patch':
        patch += 1
    else:
        raise ValueError("Unknown version type specified.")

    new_version = f"## Version: {major}.{minor}.{patch}"
    new_content = re.sub(r'^## Version: \d+\.\d+\.\d+$', new_version, content, flags=re.M)

    # Write the updated content back to the .toc file
    with open(toc_file_path, 'w') as file:
        file.write(new_content)

if __name__ == "__main__":
    version_type = sys.argv[1] if len(sys.argv) > 1 else 'patch'
    bump_version(version_type)
