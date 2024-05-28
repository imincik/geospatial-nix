import sys
import json


from lxml import etree
from subprocess import run


plugins_xml = sys.argv[1]


def fix_plugin_name(name):
    replace_chars = [".",]

    for ch in replace_chars:
        name = name.replace(ch, "-")
    return name


# generate plugins.nix code
tree = etree.parse(plugins_xml)
root = tree.getroot()

# FIXME: not sure what revision value means (doesn't look like grass-addons git revision)
# version = root.attrib["revision"]

print("{")  # opening curly

for plugin in root.findall("task"):

    package_name = fix_plugin_name(plugin.attrib["name"])
    plugin_name = plugin.attrib["name"]
    description = plugin.find("description").text

    print(
        f"""
        {package_name} = {{
            name = "{plugin_name}";
            description = ''{description}'';
        }};
    """
    )

print("}")  # closing curly
