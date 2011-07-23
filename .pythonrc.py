"""
~/.pythonrc.py

echo "export PYTHONSTARTUP=~/.pythonrc.py" >> ~/.bash_profile
"""

def __setup():
    import os
    import atexit
    import sys
    import pprint
    import readline
    import rlcompleter

    HISTORYFILE = os.path.join(os.environ['HOME'], '.python-history')
    if os.uname()[0] == 'Darwin':
        readline.parse_and_bind("bind ^I rl_complete")
    else:
        readline.parse_and_bind("tab: complete")
    try:
        readline.read_history_file(HISTORYFILE)
    except IOError:
        pass  # It doesn't exist yet.
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
