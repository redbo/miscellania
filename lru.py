"""
A simple LRU class in python.
Acts like a total dict.

This doesn't implement an lru the correct way, with a doubly-
linked list.  (correct because deque remove() is O(N) while the
doubly-linked list analogue is O(1)).

Implementing data structures in python is so slow that unless the
LRU is absolutely massive, this wrong data structure that pushes
executions down into C land is faster.
"""
import collections

class LRU(object):
    def __init__(self, size):
        self.size = size
        self._cache = {}
        self.lru = collections.deque()

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
            self.lru.popleft()
        self.lru.append(item)

    def __contains__(self, key):
        return key in self._cache


if __name__ == '__main__':
    import random, timeit
    def speed_test():
        lru = LRU(100)
        for x in xrange(500):
            lru[x] = True
    print timeit.timeit(speed_test, number=1000)

