import json
import time
import os
import shutil

# from watchdog.events import FileSystemEvent, FileSystemEventHandler
# from watchdog.observers import Observer

json_path = "./pack.json"
shaders_path = "shaders"
material_id_path = "lib/material/materialIDs.glsl"
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
        create_linked_shader_program(f"shadow", f"program/shadow.glsl")

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
                    for dim in all_dimensions.items():
                        pack["properties"].append(
                            f"program.{dim[1]}/{program_name}.enabled = {program['enabledBy']}"
                        )

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


def generate_pack():
    with open(json_path) as j:
        pack = json.loads("".join(j.readlines()))

    pack["properties"] = []

    for dim in all_dimensions.values():
        if os.path.exists(f"{shaders_path}/{dim}"):
            shutil.rmtree(f"{shaders_path}/{dim}")
    generate_gbuffers(pack)
    generate_post_processing(pack)
    generate_others(pack)
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
