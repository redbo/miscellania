"""
This jazzes up the python shell a bit.
It enables tab complete and history persistence.
It pretty-prints results.
It makes ipython-style red and green ">>" "<<" prompts.
I believe that is all.

wget 'https://github.com/redbo/miscellania/raw/master/.pythonrc.py' -O ~/.pythonrc.py
echo 'export PYTHONSTARTUP=~/.pythonrc.py' >> ~/.bash_profile
"""

def __setup():
    import os
    import atexit
    import sys
    import pprint
    import readline
    import rlcompleter
    import platform

    HISTORYFILE = os.path.join(os.environ['HOME'], '.python-history')
    if platform.system() == 'Darwin':
        readline.parse_and_bind("bind ^I rl_complete") # mac (bsd libedit)
    else:
        readline.parse_and_bind("tab: complete") # gnu readline
    try:
        readline.read_history_file(HISTORYFILE)
    except IOError:
        pass  # It doesn't exist yet.
    readline.set_history_length(100)
    atexit.register(lambda: readline.write_history_file(HISTORYFILE))

    sys.ps1 = '\n\x1b[0;32m \x1b[1;32m>>\x1b[0;32m \x1b[0m: '
    sys.ps2 = '  ... '

    _pprinter = pprint.PrettyPrinter(indent=4).pprint
    def pprinter(value):
        __builtins__._ = value # populate _ with result of previous statement
        sys.stdout.write('\x1b[0;31m \x1b[1;31m<<\x1b[0;31m \x1b[0m: ')
        _pprinter(value)
    sys.displayhook = pprinter

__setup()
del __setup
