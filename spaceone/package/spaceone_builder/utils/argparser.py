import argparse
import textwrap
import os

def parse_args():
    parser= argparse.ArgumentParser(
        description="Build SpaceONE from Infrastructure to Application with Terraform",
        epilog=textwrap.dedent('''
            Examples:
                python %(prog)s --task build
                python %(prog)s --task destroy
                python %(prog)s --task build --path /path/to/dir/
                python %(prog)s --task destroy --path /path/to/dir/
        '''
        ),formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument('--task', required=True,
                        choices=['build','destroy'],
                        help='Choose a task to build or destroy SpaceONE')

    parser.add_argument('--path', default=f'{os.getcwd()}/',
                        type=str,metavar='</path/to/dir/>',
                        help='Path to the launchpad directory of Terraform (default=current dir)')

    return parser.parse_args()
