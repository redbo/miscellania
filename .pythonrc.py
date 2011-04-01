# export PYTHONSTARTUP=~/.pythonrc.py
def _setup():
    import readline, rlcompleter
    readline.parse_and_bind("tab: complete")

    import sys
    sys.ps1 = '\n\x1b[0;32m \x1b[1;32m>>\x1b[0;32m \x1b[0m: '

    import pprint, sys
    import __builtin__
    _pprinter = pprint.PrettyPrinter(indent=4).pprint
    def pprinter(value):
        setattr(__builtin__, '_', value)
        sys.stdout.write('\x1b[0;31m \x1b[1;31m<<\x1b[0;31m \x1b[0m: ')
        _pprinter(value)
    sys.displayhook = pprinter

_setup()
del _setup
