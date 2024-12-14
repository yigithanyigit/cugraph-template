#!usr/bin/python

# This scripts running program with the given input files
#
# Usage: ./runner.py <executable path> <args of executable> <input_file dir>

import os
import sys
import subprocess
import argparse

max_level =  [50,50,50]
threshold =  [1e-3,1e-5,1e-7]
resolution = [1.0, 1.0, 1.0]
managed_memory = [0, 1]


def main():
    parser = argparse.ArgumentParser(description='Run the program with the given input files')
    parser.add_argument('executable', help='The path of the executable')
    #parser.add_argument('args', nargs=argparse.REMAINDER, help='The arguments of the executable')
    parser.add_argument('input_dir', help='The directory of the input files')
    parser.add_argument('output_dir', help='The directory of the input files')
    args = parser.parse_args()

    if not os.path.isdir(args.input_dir):
        print("The input directory is not exist")
        sys.exit(1)

    if not os.path.isdir(args.output_dir):
        print("The output directory is not exist")
        print("Creating the output directory")
        os.mkdir(args.output_dir)
        print("The output directory is created")

    input_files = os.listdir(args.input_dir)

    for input_file in input_files:
        for memory_type in managed_memory:
            input_path = os.path.join(args.input_dir, input_file)
            print("Running the program with input file: %s" % input_path)
            #subprocess.run([args.executable] + args.args + [input_path], capture_output=True, text=True)
            for level, thres, res in zip(max_level, threshold, resolution):

                print(f"{args.executable} {level} {thres} {res} {input_path} {memory_type}")
                result = subprocess.run([args.executable] + [input_path] +
                                        [str(level), str(thres), str(res), str(memory_type)],
                                        capture_output=True, text=True)
                
                if result.returncode != 0:
                    print("Error: %s" % result.stderr)
                    #sys.exit(1)

                output_file  = os.path.join(args.output_dir, f"{input_file}_{level}_{thres}_{res}_mem_type:_{memory_type}.out")
                with open(output_file, "w") as f:
                    f.write(result.stdout)


                nsys_command = ["nsys", "profile", "--stats=true" ,"--output",
                                f"{args.output_dir}/{input_file}_{level}_{thres}_{res}_mem_type:_{memory_type}_nsys_report",
                                args.executable] + [input_path] + [str(level),
                                                                   str(thres),
                                                                   str(res),
                                                                   str(memory_type)]
                
                print(f"Running command: {' '.join(nsys_command)}")
                result = subprocess.run(nsys_command, capture_output=True, text=True)
                
                if result.returncode != 0:
                    print("Error: %s" % result.stderr)
                    print("Continuing with the next input file")
                    #sys.exit(1)
                
                # Save stdout to a file
                output_file = os.path.join(args.output_dir, f"{input_file}_{level}_{thres}_{res}_nsys.out")
                with open(output_file, 'w') as f:
                    f.write(result.stdout)


if __name__ == '__main__':
    main()
