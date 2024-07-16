# -*- coding: utf-8 -*-

import os

def remove_trailing_spaces(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    with open(file_path, 'w', encoding='utf-8') as file:
        for line in lines:
            file.write(line.rstrip() + '\n')

def get_dir_files(dir_path) -> list[str]:
    return_list : list[str] = []
    for root, _, files in os.walk(dir_path):
        for file in files:
            return_list.append(os.path.join(root, file))
    return return_list

for file in get_dir_files(f'../sim'):
    remove_trailing_spaces(file)
