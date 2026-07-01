import json
import os
import shutil
import re
import urllib.request
from numpy import arange, linspace

shaders_path = "shaders"
material_id_path = "lib/material/materialIDs.glsl"
settings_path = "lib/common/settings.glsl"
lang_path = "lang/en_US.lang"
version = "460 compatibility"
minecraft_version = "26.1.2"

all_dimensions = {"OVERWORLD": "world0", "THE_NETHER": "world-1", "THE_END": "world1"}


def download_tags():
    path = f"./tags/{minecraft_version}.json"
    if not os.path.exists(path):
        if not os.path.exists("./tags"):
            os.mkdir("./tags")
        urllib.request.urlretrieve(
            f"https://raw.githubusercontent.com/InventivetalentDev/minecraft-assets/refs/heads/{minecraft_version}/data/minecraft/tags/block/_all.json",
            path,
        )


def create_linked_shader_program(
    program_path,
    file_path,
    program_types=["vsh", "fsh"],
    dimensions=all_dimensions.items(),
    defines={},
):
    for dim in dimensions:
        for program_type in program_types:
            if not os.path.exists(f"{shaders_path}/{dim[1]}/"):
                os.makedirs(f"{shaders_path}/{dim[1]}/")
            with open(
                f"{shaders_path}/{dim[1]}/{program_path}.{program_type}", "w"
            ) as p:
                program_string = []
                program_string.append(f"#version {version}")
                program_string.append(f"#define WORLD_{dim[0]}")
                program_string.append(f"#define {program_type}")
                for macro, value in defines.items():
                    program_string.append(f"#define {macro} {value}")
                program_string.append(f'#include "/{file_path}"')

                p.writelines([l + "\n" for l in program_string])


def generate_others(pack):
    for file in pack["programs"]["other"]:
        for dim in all_dimensions.items():
            if not os.path.exists(f"{shaders_path}/{dim[1]}/"):
                os.makedirs(f"{shaders_path}/{dim[1]}/")
            with open(f"{shaders_path}/{dim[1]}/{file}", "w") as p:
                program_string = []
                program_string.append(f'#include "/program/{file}"')

                p.writelines([l + "\n" for l in program_string])


def generate_gbuffers(pack):
    for program, file in pack["programs"]["gbuffers"].items():
        create_linked_shader_program(
            f"gbuffers_{program}",
            f"program/gbuffer/{file}.glsl",
            defines={f"GBUFFERS_{program.upper()}": ""},
        )

    if os.path.exists(f"{shaders_path}/program/shadow.glsl"):
        create_linked_shader_program(
            f"shadow", f"program/shadow.glsl", defines={"SHADOW": ""}
        )

    if os.path.exists(f"{shaders_path}/program/shadow_voxels.glsl"):
        create_linked_shader_program(f"shadow_voxels", f"program/shadow_voxels.glsl")


def generate_post_processing(pack):
    for stage in ["setup", "prepare", "composite", "deferred", "shadowcomp"]:
        if os.path.exists(f"{shaders_path}/program/{stage}"):
            for i, program in enumerate(pack["programs"][stage]):
                program_name = f"{stage}{i if i else ''}"

                create_linked_shader_program(
                    program_name,
                    f"program/{stage}/{program['path']}.glsl",
                    program["programs"],
                    defines=(program["defines"] if "defines" in program.keys() else {}),
                    dimensions=(
                        {
                            dim: all_dimensions[dim] for dim in program["dimensions"]
                        }.items()
                        if "dimensions" in program.keys()
                        else all_dimensions.items()
                    ),
                )

                if "blend" in program.keys():
                    pack["properties"].append(
                        f"blend.{program_name} = {program['blend']}"
                    )

                if "enabledBy" in program.keys():
                    pack["properties"].append(f"#if {program['enabledBy']}")
                    for dim in all_dimensions.items():
                        pack["properties"].append(
                            f"program.{dim[1]}/{program_name}.enabled = true"
                        )
                    pack["properties"].append(f"#else")
                    for dim in all_dimensions.items():
                        pack["properties"].append(
                            f"program.{dim[1]}/{program_name}.enabled = false"
                        )
                    pack["properties"].append(f"#endif")

    if os.path.exists(f"{shaders_path}/program/final.glsl"):
        create_linked_shader_program(f"final", f"program/final.glsl")


def generate_properties(pack):
    with open(f"{shaders_path}/shaders.properties", "r+", encoding="utf-8") as f:
        lines = f.readlines()
        if "# !AUTOGENERATE\n" in lines:
            lines = lines[0 : lines.index("# !AUTOGENERATE\n") + 1]

        lines = lines + [l + "\n" for l in pack["properties"]]
        f.seek(0)
        f.write("".join(lines))
        f.truncate()


# https://stackoverflow.com/a/47250077/12646131
def safe_arange(start, stop, step):
    return step * arange(start / step, stop / step)


def frange(start, stop, inc):
    return (
        str(safe_arange(start, stop, inc))
        .replace("\n", "")
        .replace(". ", ".0 ")
        .replace(".]", ".0]")
    )


def recurse_settings(pack, screen_name, settings, sliders, default_profile, depth=0):
    screen = f"screen{'.' if screen_name else ''}{screen_name if screen_name else ''} ="
    if depth == 0:
        screen += "<profile> "
    for name, value in settings.items():

        if name in ["profiles", "defaultProfile"]:
            continue

        if not "key" in value.keys():
            old_name = name
            name = name.replace(" ", "_")
            screen += f" [{name}]"
            pack["lang"].append(f"screen.{name} = {old_name}")
            pack["settings"].append("")
            pack["settings"].append(f"{'  ' * depth}// {name}")

            recurse_settings(pack, name, value, sliders, default_profile, depth + 1)
        else:

            if "elsewhere" in value.keys():
                screen += " " + value["key"]
                pack["lang"].append(f"option.{value['key']} = {name}")
                continue

            if "condition" in value.keys():
                pack["settings"].append(f"{'  ' * depth}#if {value['condition']}")
                pack["settings"].append(f"{'  ' * (depth + 1) }#define {value['key']}")
                pack["settings"].append(f"{'  ' * depth}#endif")
                continue

            if not "hidden" in value.keys() or (value["hidden"] == False):
                screen += f" {value["key"]}"

            if "default" in value.keys() and "defaults" in value.keys():
                raise Exception(
                    f"Setting {name} has both profile-specific defaults and a default value!"
                )

            if not "default" in value.keys():
                if "defaults" in value.keys():
                    if "*" in value["defaults"].keys():
                        for profile in pack["profiles"].keys():
                            pack["profiles"][profile][value["key"]] = value["defaults"][
                                "*"
                            ]
                        value["default"] = value["defaults"]["*"]
                    for profile, default in value["defaults"].items():
                        if profile == "*":
                            continue
                        pack["profiles"][profile][value["key"]] = default
                    if default_profile in value["defaults"].keys():
                        value["default"] = value["defaults"][default_profile]
                else:
                    value["default"] = ""
            elif not "values" in value.keys():
                value["values"] = f"[ {value['default']}]"

            disabled = False
            if isinstance(value["default"], bool):
                disabled = value["default"] == False
                value["default"] = ""

            values = ""
            if "values" in value.keys():
                values = eval('f"' + value["values"] + '"')
                values = values.replace("-", " -")
                values = re.sub(r"\s\s+", " ", values)
                values = values.replace("[ ", "[")

                values = "// " + values

                sliders.append(value["key"])

            if "const" in value.keys() and value["const"] == True:
                if "type" in value.keys():
                    t = value["type"]
                else:
                    t = "float"
                pack["settings"].append(
                    f"{'  ' * depth}{'// ' if disabled else ''}const {t} {value['key']} = {value['default']}; {values}"
                )
            else:
                pack["settings"].append(
                    f"{'  ' * depth}{'// ' if disabled else ''}#define {value['key']} {value['default']} {values}"
                )

            if value["default"] == "":
                pack["settings"].append(
                    f"{'  ' * depth}#ifdef {value['key']}\n{'  ' * depth}#endif"
                )

            if "labels" in value.keys():
                for i, label in enumerate(value["labels"]):
                    pack["lang"].append(f"value.{value['key']}.{i} = {label}")
            if "prefix" in value.keys():
                pack["lang"].append(f"prefix.{value['key']} = {value['prefix']}")
            if "suffix" in value.keys():
                pack["lang"].append(f"suffix.{value['key']} = {value['suffix']}")
            if "description" in value.keys():
                pack["lang"].append(
                    f"option.{value['key']}.comment = {value['description']}"
                )

            pack["lang"].append(f"option.{value['key']} = {name}")
    pack["properties"].append(screen)


def generate_settings(pack):
    with open("settings.json", encoding="utf-8") as s:
        settings = json.loads(s.read())
    sliders = []
    default_profile = settings["defaultProfile"]
    pack["profiles"] = {}
    for p in settings["profiles"]:
        pack["profiles"][p] = {}
    recurse_settings(pack, None, settings, sliders, default_profile)

    for profile, defaults in pack["profiles"].items():
        profile_string = f"profile.{profile.title()} = "
        for setting, value in defaults.items():
            if value == True:
                profile_string += f"{setting} "
            elif value == False:
                profile_string += f"!{setting} "
            else:
                profile_string += f"{setting}:{value} "
        pack["properties"].append(profile_string)

    pack["properties"].append(f"sliders = {' '.join(sliders)}")

    with open(f"{shaders_path}/{settings_path}", "w+") as s:
        s.write("\n".join(pack["settings"]))

    with open(f"{shaders_path}/{lang_path}", "w+", encoding="utf-8") as l:
        l.write("\n".join(pack["lang"]))


def recurse_tags(blocks, tags):
    new_blocks = []
    for block in blocks:
        if block.startswith("#") or block.startswith("%"):
            new_blocks += recurse_tags(tags[block[11:]]["values"], tags)
        else:
            new_blocks.append(block)
    return new_blocks


def generate_block_properties(pack):
    block_properties = []
    with open("blocks.json", encoding="utf-8") as b:
        block_mappings = json.loads(b.read())

    with open(f"./tags/{minecraft_version}.json") as t:
        tags = json.loads(t.read())

    inverse_block_mappings = {}
    for material, untagged_blocks in block_mappings.items():
        blocks = recurse_tags(untagged_blocks, tags)
        for block in blocks:
            if not block in inverse_block_mappings.keys():
                inverse_block_mappings[block] = [material]
            else:
                inverse_block_mappings[block].append(material)

    ids = {}
    next_id = 1000

    for i in inverse_block_mappings.keys():
        h = hash(frozenset(inverse_block_mappings[i]))
        if h not in ids.keys():
            ids[h] = next_id
            next_id += 1
        inverse_block_mappings[i] = (inverse_block_mappings[i], ids[h])

    # reverse_inverse_block_mappings = {v: k for k, v in inverse_block_mappings.items()}

    materials_to_ids = {}
    ids_to_blocks = {}
    for block, (materials, id) in inverse_block_mappings.items():
        for material in materials:
            if not material in materials_to_ids.keys():
                materials_to_ids[material] = [id]
            elif id not in materials_to_ids[material]:
                materials_to_ids[material].append(id)

        if not id in ids_to_blocks.keys():
            ids_to_blocks[id] = [block]
        else:
            ids_to_blocks[id].append(block)

    for id, blocks in ids_to_blocks.items():
        block_properties.append(f"block.{id} = {" ".join(blocks)}")
    with open(f"{shaders_path}/block.properties", "w") as f:
        f.writelines([b + "\n" for b in block_properties])

    mapping_functions = []

    for material, ids in materials_to_ids.items():
        title = material
        prefix = "material"
        if not title.split(" ")[0] in ["lets", "emits"]:
            prefix += "Is"

        if len(ids) == 1:
            mapping_functions.append(
                f"bool {(prefix + title.title()).replace(" ", "")}(uint id){{return id == {ids[0]};}}"
            )
            mapping_functions.append(
                f"#define MATERIAL_{title.upper().replace(" ", "_")} {ids[0]}"
            )
        else:
            mapping_function = (
                f"bool {(prefix + title.title()).replace(" ", "")}(uint id){{return "
            )
            for id in ids:
                mapping_function += f"id == {id} || "
            mapping_function = mapping_function[:-4] + ";}"
            mapping_functions.append(mapping_function)

    with open(f"{shaders_path}/{material_id_path}", "w") as f:
        f.writelines([f + "\n" for f in mapping_functions])


# def generate_material_ids(pack):
#     block_properties = []
#     mappings = []
#     for i, (group_name, blocks) in enumerate(pack["blockMappings"].items()):
#         block_properties.append(f"block.{i + 1000} = {blocks}")
#         mappings.append(
#             f"bool materialIs{group_name.title()}(uint id){{return id == {i + 1000};}}"
#         )

#     with open(f"{shaders_path}/block.properties", "w") as f:
#         f.writelines(block_properties)
#     with open(f"{shaders_path}/{material_id_path}", "w") as f:
#         f.writelines(mappings)


def generate_pack():
    download_tags()

    with open("./pack.json", encoding="utf-8") as j:
        pack = json.loads("".join(j.readlines()))

    pack["properties"] = []
    pack["settings"] = []
    pack["lang"] = []

    for dim in all_dimensions.values():
        if os.path.exists(f"{shaders_path}/{dim}"):
            shutil.rmtree(f"{shaders_path}/{dim}")
    generate_gbuffers(pack)
    generate_post_processing(pack)
    generate_others(pack)
    generate_settings(pack)
    generate_properties(pack)
    generate_block_properties(pack)


generate_pack()

# class Handler(FileSystemEventHandler):
#   def on_any_event(self, event: FileSystemEvent) -> None:
#     try:
#       print("Rebuilding...")
#       generate_pack()

#     except Exception:
#       return

# if __name__ == "__main__":
#   generate_pack()
#   # observer = Observer()
#   # handler = Handler()
#   # observer.schedule(handler, json_path)
#   # observer.schedule(handler, shaders_path, recursive=True)
#   # observer.start()

#   # try:
#   #   while True:
#   #     time.sleep(1)
#   # finally:
#   #   observer.stop()
#   #   observer.join()
