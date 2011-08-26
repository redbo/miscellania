import threading
import socket
import time
import sys


timeout_stack = threading.local()

if not hasattr(socket, '_timeout_patched'):
    class new_socket(socket.socket):
        def __init__(self, *args, **kwargs):
            super(new_socket, self).__init__(*args, **kwargs)

            def patch(method_name):
                old_method = getattr(super(new_socket, self), method_name)
                def _patched_method(*args, **kwargs):
                    if not getattr(timeout_stack, 'values', None):
                        return old_method(*args, **kwargs)
                    timeout, exception = min(timeout_stack.values)
                    self.settimeout(timeout - time.time())
                    try:
                        return old_method(*args, **kwargs)
                    except socket.timeout:
                        cls, value, traceback = sys.exc_info()
                        raise type(exception), exception, traceback
                return _patched_method

            for method_name in ('recv', 'sendall', 'sendto', 'connect',
                        'recvfrom', 'recvfrom_into', 'accept', 'send'):
                setattr(self, method_name, patch(method_name))

    socket.socket = new_socket
    socket._timeout_patched = True


class Timeout(BaseException):
    def __init__(self, timeout):
        self.timeout = timeout
        if not hasattr(timeout_stack, 'values'):
            timeout_stack.values = []

    def __enter__(self):
        this_timeout = time.time() + self.timeout
        timeout_stack.values.append((this_timeout, self))

    def __exit__(self, cls, value, traceback):
        timeout_stack.values.pop()

if __name__ == '__main__':
    with Timeout(5):
        x = socket.socket(socket.AF_INET)
        x.connect(('1.1.1.1', 8192))

