#!/usr/bin/env python3
import os
import subprocess


def generate_file(name, outpath, **kwargs):
    from jinja2 import Environment, FileSystemLoader
    env = Environment(loader=FileSystemLoader('.'))
    template = env.get_template(name)
    path = os.path.join(outpath, name.replace('_template', ''))
    with open(path, 'w') as fp:
        fp.write(template.render(kwargs))
    subprocess.run(["stylua", path])


if __name__ == '__main__':
    generate_file('bind_tbl_template.lua', '../lua/libp/functional', amount=16)
