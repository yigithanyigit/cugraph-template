"""
YUSUF ATMACA 2024
YIGITHAN YIGIT 2024


Edge list to matrix market format converter.
"""

import pandas as pd
from scipy.io import mmwrite
from scipy.sparse import coo_matrix
import argparse

parser = argparse.ArgumentParser(description="Convert edge list to matrix market format.")
parser.add_argument("input_file", help="Input edge list file")
parser.add_argument("output_file", nargs='?', help="Output matrix market file (default: same as input with .mtx extension)")

args = parser.parse_args()

input_file = args.input_file
output_file = args.output_file if args.output_file else input_file.rsplit('.', 1)[0] + ".mtx"

edges = pd.read_csv(
    input_file,
    delimiter="\t",
    comment="#",
    names=["FromNodeId", "ToNodeId"],
    dtype={"FromNodeId": int, "ToNodeId": int},
)


num_nodes = edges[["FromNodeId", "ToNodeId"]].max().max() + 1
row = edges["FromNodeId"].values
col = edges["ToNodeId"].values
data = [1] * len(edges)
adj_matrix = coo_matrix((data, (row, col)), shape=(num_nodes, num_nodes))

mmwrite(output_file, adj_matrix)

print(f"Converted {input_file} to {output_file}")

