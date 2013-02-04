cdef extern from "Python.h":
    void Py_INCREF(object)
    void Py_DECREF(object)


cdef extern from 'sqlite3.h':
    struct sqlite3:
        pass
    struct sqlite3_stmt:
        pass
    struct sqlite3_context:
        pass
    ctypedef int sqlite3_int64
    ctypedef int sqlite3_value
    int sqlite3_open_v2(char *filename, sqlite3 **ppDb, int flags, char *zVfs) nogil
    int sqlite3_prepare_v2(sqlite3 *db, char *zSql, int nByte,
        sqlite3_stmt **ppStmt, char **pzTail) nogil
    int sqlite3_step(sqlite3_stmt*) nogil
    int sqlite3_finalize(sqlite3_stmt *pStmt) nogil
    int sqlite3_close(sqlite3*)
    void *sqlite3_user_data(sqlite3_context*)
    int sqlite3_changes(sqlite3*)
    sqlite3 *sqlite3_db_handle(sqlite3_stmt*)
    char *sqlite3_column_name(sqlite3_stmt*, int N)

    int sqlite3_create_function_v2(sqlite3 *db, char *zFunctionName, int nArg,
        int eTextRep, void *pApp,
        void (*xFunc)(sqlite3_context*, int, sqlite3_value**),
        void (*xStep)(sqlite3_context*, int, sqlite3_value**),
        void (*xFinal)(sqlite3_context*), void(*xDestroy)(void*))

    int sqlite3_column_count(sqlite3_stmt *pStmt)
    int sqlite3_column_bytes(sqlite3_stmt*, int iCol)
    double sqlite3_column_double(sqlite3_stmt*, int iCol)
    sqlite3_int64 sqlite3_column_int64(sqlite3_stmt*, int iCol)
    unsigned char *sqlite3_column_text(sqlite3_stmt*, int iCol)
    int sqlite3_column_type(sqlite3_stmt*, int iCol)

    int sqlite3_bind_double(sqlite3_stmt*, int, double)
    int sqlite3_bind_int64(sqlite3_stmt*, int, sqlite3_int64)
    int sqlite3_bind_null(sqlite3_stmt*, int)
    int sqlite3_bind_text(sqlite3_stmt*, int, char*, int n, void(*)(void*))

    int sqlite3_value_bytes(sqlite3_value*)
    double sqlite3_value_double(sqlite3_value*)
    sqlite3_int64 sqlite3_value_int64(sqlite3_value*)
    unsigned char *sqlite3_value_text(sqlite3_value*)
    int sqlite3_value_type(sqlite3_value*)

    void sqlite3_result_double(sqlite3_context*, double)
    void sqlite3_result_error(sqlite3_context*, char*, int)
    void sqlite3_result_error_toobig(sqlite3_context*)
    void sqlite3_result_error_nomem(sqlite3_context*)
    void sqlite3_result_error_code(sqlite3_context*, int)
    void sqlite3_result_int64(sqlite3_context*, sqlite3_int64)
    void sqlite3_result_null(sqlite3_context*)
    void sqlite3_result_text(sqlite3_context*, char*, int, void(*)(void*))

    int SQLITE_OK, SQLITE_BUSY, SQLITE_DONE, SQLITE_ROW, SQLITE_ERROR, SQLITE_MISUSE
    int SQLITE_OPEN_READWRITE, SQLITE_OPEN_CREATE, SQLITE_OPEN_READONLY
    int SQLITE_INTEGER, SQLITE_FLOAT, SQLITE_TEXT, SQLITE_BLOB, SQLITE_NULL
    int SQLITE_ANY
    void SQLITE_TRANSIENT(void *)


class SQLiteError(Exception):
    pass


cdef object value_args(int argc, sqlite3_value **val):
    cdef int type
    cdef int length
    args = []
    for arg in xrange(argc):
        type = sqlite3_value_type(val[arg])
        if type == SQLITE_INTEGER:
            args.append(sqlite3_value_int64(val[arg]))
        elif type == SQLITE_FLOAT:
            args.append(sqlite3_value_double(val[arg]))
        elif type == SQLITE_NULL:
            args.append(None)
        elif type in (SQLITE_BLOB, SQLITE_TEXT):
            length = sqlite3_value_bytes(val[arg])
            args.append(sqlite3_value_text(val[arg])[0:length])
        else:
            args.append(None)
    return args


cdef obj_result(sqlite3_context *ctx, obj):
    if isinstance(obj, (int, long)):
        sqlite3_result_int64(ctx, obj)
    elif isinstance(obj, float):
        sqlite3_result_double(ctx, obj)
    elif isinstance(obj, unicode):
        obj = obj.encode('utf-8')
        sqlite3_result_text(ctx, obj, len(obj), SQLITE_TRANSIENT)
    elif isinstance(obj, str):
        sqlite3_result_text(ctx, obj, len(obj), SQLITE_TRANSIENT)
    elif isinstance(obj, None):
        sqlite3_result_null(ctx)


cdef void call_udf(sqlite3_context *ctx, int argc, sqlite3_value **argv) with gil:
    cdef int type, length
    args = value_args(argc, argv)
    callable = <object>sqlite3_user_data(ctx);
    result = callable(*args)
    obj_result(ctx, result)


cdef void call_agg_step(sqlite3_context *ctx, int argc, sqlite3_value **argv) with gil:
    cdef int type, length
    args = value_args(argc, argv)
    agg = <object>sqlite3_user_data(ctx);
    if not agg[1]:
        agg[1] = agg[0]()
    agg[1].step(*args)


cdef void call_agg_finalize(sqlite3_context *ctx) with gil:
    agg = <object>sqlite3_user_data(ctx);
    if not agg[1]:
        agg[1] = agg[0]()
    result = agg[1].finalize()
    obj_result(ctx, result)
    agg[1] = None


cdef void destroy_udf(void *callable) with gil:
    Py_DECREF(<object>callable)


cdef check(int response):
    if response != SQLITE_OK:
        raise SQLiteError('ERROR %d' % response)


cdef class SQLiteRow(object):
    """
    dict-alike that uses less memory per result
    """
    cdef object values, column_locations

    def __init__(self, values, column_locations):
        self.values = values
        self.column_locations = column_locations

    def keys(self):
        return self.column_locations.keys()

    def __iter__(self):
        return iter(self.keys())

    def __contains__(self, key):
        if isinstance(key, (int, long)):
            return key < len(self.values)
        else:
            return key in self.column_locations

    def items(self):
        return list(self.iteritems())

    def iteritems(self):
        return ((name, self.values[i])
                for name, i in self.column_locations.iteritems())

    def __getitem__(self, key):
        if isinstance(key, (int, long)):
            return self.values[key]
        else:
            return self.values[self.column_locations[key]]

    def __repr__(self):
        return '{' + ', '.join('%s: %s' % (repr(name), repr(self.values[i])) \
            for name, i in self.column_locations.iteritems()) + '}'
    __str__ = __repr__


cdef class SQLiteStatement(object):
    cdef sqlite3_stmt *stmt
    cdef int rowcount, columncount
    cdef object columns, column_locations

    def __init__(self):
        self.rowcount = 0
        self.column_locations = None

    def populate_columns(self):
        self.columncount = sqlite3_column_count(self.stmt)
        self.column_locations = {}
        for column in xrange(self.columncount):
            column_name = sqlite3_column_name(self.stmt, column)[:]
            self.column_locations[column_name] = column

    def next_row(self):
        cdef int rc, length, column_type
        rc = SQLITE_ROW
        if self.column_locations is None:
            self.populate_columns()
        while rc != SQLITE_DONE:
            with nogil:
                rc = sqlite3_step(self.stmt)
            if rc == SQLITE_ROW:
                results = []
                for column in xrange(self.columncount):
                    column_type = sqlite3_column_type(self.stmt, column)
                    if column_type == SQLITE_INTEGER:
                        results.append(sqlite3_column_int64(self.stmt, column))
                    elif column_type == SQLITE_FLOAT:
                        results.append(sqlite3_column_double(self.stmt, column))
                    elif column_type in (SQLITE_TEXT, SQLITE_BLOB):
                        length = sqlite3_column_bytes(self.stmt, column)
                        results.append(sqlite3_column_text(self.stmt, column)[0:length])
                    elif column_type == SQLITE_NULL:
                        results.append(None)
                return SQLiteRow(results, self.column_locations)
        raise StopIteration()

    def exhaust(self):
        cdef int rc
        rc = SQLITE_ROW
        while rc != SQLITE_DONE:
            with nogil:
                rc = sqlite3_step(self.stmt)
        self.rowcount = sqlite3_changes(sqlite3_db_handle(self.stmt))

    def __dealloc__(self):
        with nogil:
            sqlite3_finalize(self.stmt)


class SQLiteCursor(object):
    """
    this wrapper exists because cdef classes can't be iterables
    """
    def __init__(self, cursor):
        self.cursor = cursor

    def __iter__(self):
        return self

    def next(self):
        return self.cursor.next_row()

    def __getattr__(self, name):
        return getattr(self.cursor, name)


cdef class SQLiteConnection(object):
    cdef sqlite3 *db_connection

    def __init__(self, filename, mode='wc'):
        cdef int rc
        cdef int flags
        if 'w' in mode:
            flags = SQLITE_OPEN_READWRITE
        else:
            flags = SQLITE_OPEN_READONLY
        if 'c' in mode:
            flags |= SQLITE_OPEN_CREATE
        with nogil:
            rc = sqlite3_open_v2(filename, &self.db_connection, flags, NULL)
        check(rc)

    def query(self, query, *args):
        cdef SQLiteStatement stmt = SQLiteStatement()
        cdef int rc
        cdef int length = len(query)
        with nogil:
            rc = sqlite3_prepare_v2(self.db_connection, query, length,
                                 &stmt.stmt, NULL)
        check(rc)
        for i, arg in enumerate(args):
            if isinstance(arg, (int, long)):
                check(sqlite3_bind_int64(stmt.stmt, i, arg))
            if isinstance(arg, (float)):
                check(sqlite3_bind_double(stmt.stmt, i, arg))
            elif isinstance(arg, unicode):
                arg = arg.encode('utf-8')
                check(sqlite3_bind_text(stmt.stmt, i, arg, len(arg), SQLITE_TRANSIENT))
            elif isinstance(arg, str):
                check(sqlite3_bind_text(stmt.stmt, i, arg, len(arg), SQLITE_TRANSIENT))
            elif arg is None:
                check(sqlite3_bind_null(stmt.stmt, i))
        return SQLiteCursor(stmt)

    def execute(self, query, *args):
        res = self.query(query, *args)
        res.exhaust()
        return res

    def create_function(self, name, args, callable):
        Py_INCREF(callable)
        check(sqlite3_create_function_v2(self.db_connection, name, args,
                SQLITE_ANY, <void *>callable,
                call_udf, NULL, NULL, destroy_udf))

    def create_aggregate(self, name, args, aggregator_cls):
        if not hasattr(aggregator_cls, 'step') or not \
                hasattr(aggregator_cls, 'finalize'):
            raise Exception('Incorrect aggregator interface')
        agg = [aggregator_cls, None]
        Py_INCREF(agg)
        check(sqlite3_create_function_v2(self.db_connection, name, args,
                SQLITE_ANY, <void *>agg,
                NULL, call_agg_step, call_agg_finalize, destroy_udf))

    def destroy_function(self, name, args):
        check(sqlite3_create_function_v2(self.db_connection, name, args,
                SQLITE_ANY, NULL, NULL, NULL, NULL, NULL))

    def create_tokenizer(self, name, callable):
        pass

    def __dealloc__(self):
        if self.db_connection:
            sqlite3_close(self.db_connection)
