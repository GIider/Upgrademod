import os
import shutil
import subprocess
import re

THIS_DIR = os.path.abspath(os.path.dirname(__file__))

BASE_DIR = os.path.abspath(os.path.join(THIS_DIR, '..'))

SOURCE_DIR = os.path.join(BASE_DIR, 'sourcemod', 'scripting')
THIRD_PARTY_DIR = os.path.join(BASE_DIR, 'third_party', 'sourcemod', 'scripting')
BUILD_DIR = os.path.join(BASE_DIR, '__build')

PLUGINS_DIR = r'X:\SERVERZ\l4d2\left4dead2\addons\sourcemod\plugins\upgrademod'
COMPILED_DIR = os.path.join(BUILD_DIR, 'compiled')

def clean_build_directory():
    print('Cleaning __build directory')
    try:
        shutil.rmtree(BUILD_DIR)
    except FileNotFoundError:
        print('... Nothing to clean!')

def copy_files():
    print('Copying files')
    cmd = 'ROBOCOPY {} {} /E'
    subprocess.call(cmd.format(SOURCE_DIR, BUILD_DIR))
    subprocess.call(cmd.format(THIRD_PARTY_DIR, BUILD_DIR))

    # shutil.copytree(SOURCE_DIR, BUILD_DIR)
    # shutil.copy2(THIRD_PARTY_DIR, BUILD_DIR)

def compile():
    print('Compiling')
    os.chdir(BUILD_DIR)
    compiler_process = subprocess.Popen('compile.exe', stdout=subprocess.PIPE,
                                                       stdin=subprocess.PIPE)
    stdout, stderr = compiler_process.communicate(b'\n')
    stdout = stdout.decode('ascii')

    has_errors = False
    for match in re.finditer(r'/{4}.+?// ----------------------------------------', stdout, re.DOTALL):
        if re.search(r'\d+ Error', match.group()):
            print(match.group())
            has_errors = True

        if re.search(r'\d+ Warning', match.group()):
            print(match.group())

    return not has_errors

def update_server_folder():
    print('Removing old upgrademod version')
    try:
        shutil.rmtree(PLUGINS_DIR)
    except OSError:
        pass

    print('Copying new upgrademod version')
    shutil.copytree(COMPILED_DIR, PLUGINS_DIR)

if __name__ == '__main__':
    clean_build_directory()
    copy_files()
    compile_was_successful = compile()
    if compile_was_successful:
        update_server_folder()

    print('ALL DONE')
