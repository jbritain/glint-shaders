'''
    ┏┓┓•   
    ┃┓┃┓┏┓╋
    ┗┛┗┗┛┗┗
    By jbritain
    https://jbritain.net

		Copies files from base dimension folder to other dimensions
'''

import glob
from shutil import rmtree, copyfile
from os import makedirs
from os.path import normpath

base_dimension = ("world0", "WORLD_OVERWORLD")

dimensions = [
  ("world-1", "WORLD_THE_NETHER"),
  ("world1", "WORLD_THE_END")
]


# clear out the dirs
for dimension in dimensions:
  try:
    rmtree(f"./shaders/{dimension[0]}")
  except Exception:
    pass

makedirs(f"./shaders/{dimension[0]}")

# get list of programs
shader_programs = glob.glob(f"./shaders/{base_dimension[0]}/*")

# for each program, copy it to every other dimension's directory, and replace the name definition with relevant dimension name
for dimension in dimensions:
  for program in shader_programs:
    new_program = program.replace(base_dimension[0], dimension[0])
    copyfile(program, new_program)