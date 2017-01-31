#!/bin/env python
import argparse
import os
import sys

from dockerfile_parse import DockerfileParser


def check_file_exists(file_to_check):
    return os.path.exists(file_to_check)


def add_env(docker_file, docker_env, docker_val):

    dfp = DockerfileParser()
    docker_content = open(docker_file).read()

    dfp.content = docker_content
    env_line = "ENV {}={}".format(docker_env, docker_val)

    # if env already in Dockerfile, use DockerfileParser to modify it
    # else, add the env_line just after the 'FROM ' line
    # The way DockerfileParser deals with adding new envs is not optimal
    # (adds it to end of file), this is why we need another method to add *new*
    # env
    if docker_env in dfp.envs:
        dfp.envs[docker_env] = docker_val
        with open(docker_file, 'w') as f:
            f.write(dfp.content)

    else:
        index = -1
        lines = docker_content.split('\n')
        for i, line in enumerate(lines):
            if line.strip().startswith('FROM '):
                index = i
                break
        if index != -1:
            lines.insert(index + 1, env_line)
            with open(docker_file, 'w') as f:
                f.write('\n'.join(lines))


def main():
    parser = argparse.ArgumentParser(description='Change Dockerfile envs')
    parser.add_argument('-f', '--file',
                        help='Dockerfile location', required=True)
    parser.add_argument('-e', '--environment',
                        help='Environment', required=True)
    parser.add_argument('-v', '--value',
                        help='Environment value', required=True)

    args = parser.parse_args()

    docker_loc = args.file
    docker_env = args.environment
    docker_env_val = args.value

    if not check_file_exists(docker_loc):
        print("File '" + docker_loc + "' doesn't exist!")
        sys.exit(1)

    add_env(docker_loc, docker_env, docker_env_val)

main()
