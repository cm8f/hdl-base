#!/bin/python

from os.path import join,dirname
from vunit import VUnit, VUnitCLI
from glob import glob
from subprocess import call
import imp

def post_run(results):
    results.merge_coverage(file_name="coverage_data")
    if VU.get_simulator_name() == "ghdl":
        call(["gcovr", "-x", "coverage.xml", "coverage_data"])
        call(["gcovr", "-o", "coverage.txt", "coverage_data"])

def create_test_suites(prj, args):
    root = dirname(__file__)
    run_scripts = glob(join(root, "*", "run.py"))

    for run_script in run_scripts:
        file_handle, path_name, description = imp.find_module("run", [dirname(run_script)])
        run = imp.load_module("run", file_handle, path_name, description)
        run.create_test_suite(prj, args)
        file_handle.close()


cli = VUnitCLI()
cli.parser.add_argument('--cover', type=int, default=0, help='Enable ghdl coverage')
args = cli.parse_args()

VU = VUnit.from_args(args=args)
VU.add_osvvm()
create_test_suites(VU, args)
if args.cover < 1:
    VU.main()
else:
    VU.main(post_run=post_run)
