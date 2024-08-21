from block_wrangler import *
from pathlib import Path


shaderpack_root = Path(__file__).parent

def main():
	tags = load_tags()

	mapping = BlockMapping.solve({
		'water': blocks('minecraft:water')
	},
	pragma="MATERIAL_IDS_INCLUDE",
	function_name="material_{flag}",
	start_index=10001
  )

	with shaderpack_root.joinpath('shaders/block.properties').open('w') as f:
		f.write(mapping.render_encoder())
	with shaderpack_root.joinpath('shaders/lib/util/materialIDs.glsl').open('w') as f:
		f.write(mapping.render_decoder())

if __name__ == '__main__':
	main()