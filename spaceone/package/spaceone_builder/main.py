from python_terraform import *
from utils import argparser
import os,sys,time, datetime

terraform = Terraform()
cmd_args = argparser.parse_args()

def timer(func):
    def wrap_func(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        during_time = str(datetime.timedelta(seconds=round(end-start)))

        if func.__name__ == 'terraform_execute':
            print(f'...{during_time}')
            return result

        print(f'{func.__name__!r} executed in {during_time}')
        return result
    return wrap_func

@timer
def terraform_execute(part,cmd,*args):
    path = f'{cmd_args.path}{part}'
    os.chdir(path)

    return_code, stdout, stderr = terraform.cmd(cmd,*args)

    if not return_code:
        print(f'[{part}] {cmd} Successfully')
    else:
        print(f'[{part}] An error has occurred : {stderr}')
        sys.exit(1)

@timer
def build_spaceone(parts):
    for part in parts:
        terraform_execute(part, 'init')
        terraform_execute(part, 'plan')
        terraform_execute(part, 'apply', '-auto-approve')

@timer
def destroy_spaceone(parts):
    parts.reverse()
    for part in parts:
        print("")
        terraform_execute(part, 'destroy', '-auto-approve')

def main():
    parts = [
        "certificate",
        "eks",
        "controllers",
        "deployment",
        "initialization"
    ]

    if cmd_args.task == 'build':
        build_spaceone(parts)
    elif cmd_args.task == 'destroy':
        destroy_spaceone(parts)
