import sys
import json


from lxml import etree
from subprocess import run


MIN_DOWNLOADS = 100000

qgis_plugins_xml = sys.argv[1]


def get_nix_hash(url):
    cmd = run(
        ["nix", "store", "prefetch-file", "--json", url], capture_output=True, text=True
    )
    return json.loads(cmd.stdout)["hash"]


def fix_plugin_name(name):
    replace_chars = [" ", ".", ":", "(", ")"]

    for ch in replace_chars:
        name = name.replace(ch, "-")
    return name


# generate plugins.nix code
tree = etree.parse(qgis_plugins_xml)
root = tree.getroot()

print("{")  # opening curly

for plugin in root.findall("pyqgis_plugin"):
    # get non-experimental plugins with more than MIN_DOWNLOADS
    if (
        plugin.find("experimental").text == "False"
        and plugin.find("deprecated").text == "False"
        and int(plugin.find("downloads").text) > MIN_DOWNLOADS
    ):
        name = fix_plugin_name(plugin.attrib["name"])
        url = plugin.find("download_url").text
        version = plugin.find("version").text
        hash = get_nix_hash(url)

        print(
            f"""
            {name} = {{
                version = "{version}";
                url = "{url}";
                hash = "{hash}";
            }};
        """
        )

print("}")  # closing curly
