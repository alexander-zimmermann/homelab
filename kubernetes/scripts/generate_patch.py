import sys
import argparse
import yaml
import os

def str_presenter(dumper, data):
    if len(data.splitlines()) > 1:  # check for multiline string
        return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')
    return dumper.represent_scalar('tag:yaml.org,2002:str', data)

yaml.add_representer(str, str_presenter)

def main():
    parser = argparse.ArgumentParser(description="Inject stdin content into a Patch YAML file.")
    parser.add_argument("--target", required=True, help="Path to the target patch YAML file")
    parser.add_argument("--name", required=True, help="Name of the inlineManifest entry")
    args = parser.parse_args()

    # Read rendered manifest from pipeline (stdin)
    content = sys.stdin.read()

    if not content:
        print("Error: No content received from stdin")
        sys.exit(1)

    # Ensure target directory exists
    os.makedirs(os.path.dirname(args.target), exist_ok=True)

    # Prepare raw patch content (Omni expects the config map directly when using file: reference)
    patch_data = {
         "cluster": {
             "inlineManifests": [
                 {
                     "name": args.name,
                     "contents": content
                 }
             ]
         }
    }

    # Write to file
    with open(args.target, 'w') as f:
        yaml.dump(patch_data, f, default_flow_style=False, sort_keys=False)

    print(f"✅ Injected patch content into {args.target}")

if __name__ == "__main__":
    main()
