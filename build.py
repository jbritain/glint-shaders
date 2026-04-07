import json
import time
import os
import shutil
import re
from numpy import arange

# from watchdog.events import FileSystemEvent, FileSystemEventHandler
# from watchdog.observers import Observer

json_path = "./pack.json"
shaders_path = "shaders"
material_id_path = "lib/material/materialIDs.glsl"
settings_path = "lib/common/settings.glsl"
lang_path = "lang/en_US.lang"
version = "460 compatibility"

all_dimensions = {"OVERWORLD": "world0", "THE_NETHER": "world-1", "THE_END": "world1"}


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


def generate_material_ids(pack):
    block_properties = []
    mappings = []
    for i, (group_name, blocks) in enumerate(pack["blockMappings"].items()):
        block_properties.append(f"block.{i + 1000} = {blocks}")
        mappings.append(
            f"bool materialIs{group_name.title()}(uint id){{return id == {i + 1000};}}"
        )

    with open(f"{shaders_path}/block.properties", "w") as f:
        f.writelines(block_properties)
    with open(f"{shaders_path}/{material_id_path}", "w") as f:
        f.writelines(mappings)


def frange(start, stop, inc):
    return (
        str(arange(start, stop, inc))
        .replace("\n", "")
        .replace(". ", ".0")
        .replace(".]", ".0]")
    )


def recurse_settings(pack, screen_name, settings, sliders, depth=0):
    screen = f"screen{'.' if screen_name else ''}{screen_name if screen_name else ''} ="
    for name, value in settings.items():

        if not "key" in value.keys():
            old_name = name
            name = name.replace(" ", "_")
            screen += f" [{name}]"
            pack["lang"].append(f"screen.{name} = {old_name}")
            pack["settings"].append("")
            pack["settings"].append(f"{'  ' * depth}// {name}")

            recurse_settings(pack, name, value, sliders, depth + 1)
        else:
            if "condition" in value.keys():
                pack["settings"].append(f"{'  ' * depth}#if {value['condition']}")
                pack["settings"].append(f"{'  ' * (depth + 1) }#define {value['key']}")
                pack["settings"].append(f"{'  ' * depth}#endif")
                continue

            if not "hidden" in value.keys() or (value["hidden"] == False):
                screen += f" {value["key"]}"

            if not "default" in value.keys():
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

            if "descriptions" in value.keys():
                for i, description in enumerate(value["descriptions"]):
                    pack["lang"].append(f"value.{value["key"]}.{i} = {description}")

            pack["lang"].append(f"option.{value['key']} = {name}")
    pack["properties"].append(screen)


def generate_settings(pack):
    with open("settings.json") as s:
        settings = json.loads(s.read())
    sliders = []
    recurse_settings(pack, None, settings, sliders)

    pack["properties"].append(f"sliders = {' '.join(sliders)}")

    with open(f"{shaders_path}/{settings_path}", "w+") as s:
        s.write("\n".join(pack["settings"]))

    with open(f"{shaders_path}/{lang_path}", "w+") as l:
        l.write("\n".join(pack["lang"]))


def generate_pack():
    with open(json_path) as j:
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
    generate_material_ids(pack)


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
