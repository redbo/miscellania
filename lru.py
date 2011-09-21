"""
A simple LRU class in python.
Acts like a total dict.
"""

class LRU(object):
    def __init__(self, size):
        self.size = size
        self._cache = {}
        self.lru = []

    def __getitem__(self, key):
        item = self._cache[key]
        self.lru.remove(item)
        self.lru.append(item)
        return item[1]

    def __setitem__(self, key, value):
        if key in self._cache:
            raise KeyError('exists')
        item = (key, value)
        self._cache[key] = item
        if len(self._cache) > self.size:
            del self._cache[self.lru[0][0]]
            self.lru.pop(0)
        self.lru.append(item)

    def __contains__(self, key):
        return key in self._cache

