import sqlite3
from contextlib import contextmanager
from pathlib import Path


class DatabaseError(Exception):
    pass


class IntegrityError(DatabaseError):
    pass


def _normalize_database_url(url):
    value = str(url or "").strip()
    if not value:
        return ""
    if value.startswith("postgres://"):
        return "postgresql://" + value[len("postgres://") :]
    return value


def _adapt_placeholders(sql, dialect):
    if dialect == "postgresql":
        return sql.replace("?", "%s")
    return sql


class _CursorProxy:
    def __init__(self, cursor, dialect):
        self._cursor = cursor
        self._dialect = dialect

    @property
    def rowcount(self):
        return self._cursor.rowcount

    def fetchone(self):
        row = self._cursor.fetchone()
        if row is None:
            return None
        if self._dialect == "sqlite":
            return dict(row)
        return row

    def fetchall(self):
        rows = self._cursor.fetchall()
        if self._dialect == "sqlite":
            return [dict(row) for row in rows]
        return rows


class _ConnectionProxy:
    def __init__(self, connection, dialect):
        self._connection = connection
        self._dialect = dialect

    def execute(self, sql, params=()):
        try:
            cursor = self._connection.execute(
                _adapt_placeholders(sql, self._dialect),
                params,
            )
        except sqlite3.IntegrityError as error:
            raise IntegrityError(str(error)) from error
        except Exception as error:
            if self._dialect == "postgresql":
                try:
                    import psycopg.errors

                    if isinstance(
                        error,
                        (
                            psycopg.errors.UniqueViolation,
                            psycopg.errors.ForeignKeyViolation,
                        ),
                    ):
                        raise IntegrityError(str(error)) from error
                except ImportError:
                    pass
            raise
        return _CursorProxy(cursor, self._dialect)

    def executemany(self, sql, params_list):
        try:
            adapted_sql = _adapt_placeholders(sql, self._dialect)
            if hasattr(self._connection, "executemany"):
                self._connection.executemany(adapted_sql, params_list)
            else:
                for params in params_list:
                    self._connection.execute(adapted_sql, params)
        except sqlite3.IntegrityError as error:
            raise IntegrityError(str(error)) from error
        except Exception as error:
            if self._dialect == "postgresql":
                try:
                    import psycopg.errors

                    if isinstance(
                        error,
                        (
                            psycopg.errors.UniqueViolation,
                            psycopg.errors.ForeignKeyViolation,
                        ),
                    ):
                        raise IntegrityError(str(error)) from error
                except ImportError:
                    pass
            raise

    def commit(self):
        self._connection.commit()

    def close(self):
        self._connection.close()

    def table_columns(self, table_name):
        if self._dialect == "sqlite":
            rows = self.execute(f"pragma table_info({table_name})").fetchall()
            return {row["name"] for row in rows}
        rows = self.execute(
            """
            select column_name
            from information_schema.columns
            where table_schema = 'public' and table_name = ?
            """,
            (table_name,),
        ).fetchall()
        return {row["column_name"] for row in rows}


class Database:
    def __init__(self, *, database_url="", sqlite_path=""):
        self.database_url = _normalize_database_url(database_url)
        self.sqlite_path = str(sqlite_path or "").strip()
        self.dialect = "postgresql" if self.database_url else "sqlite"
        if self.dialect == "sqlite" and not self.sqlite_path:
            raise DatabaseError("SQLite path is required when DATABASE_URL is not set")

    @classmethod
    def from_config(cls, config):
        database_url = _normalize_database_url(config.get("DATABASE_URL", ""))
        if database_url:
            return cls(database_url=database_url)
        sqlite_path = config.get(
            "APP_DATABASE_FILE",
            "instance/operations.sqlite3",
        )
        return cls(sqlite_path=sqlite_path)

    @property
    def engine(self):
        return "postgresql" if self.dialect == "postgresql" else "sqlite"

    def _connect(self):
        if self.dialect == "postgresql":
            import psycopg
            from psycopg.rows import dict_row

            connection = psycopg.connect(self.database_url, row_factory=dict_row)
            return _ConnectionProxy(connection, "postgresql")

        path = Path(self.sqlite_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        connection = sqlite3.connect(path)
        connection.row_factory = sqlite3.Row
        return _ConnectionProxy(connection, "sqlite")

    @contextmanager
    def session(self):
        connection = self._connect()
        try:
            yield connection
        finally:
            connection.close()

    def execute_script(self, statements):
        with self.session() as connection:
            for statement in statements:
                text = statement.strip()
                if text:
                    connection.execute(text)
            connection.commit()


def create_database(config):
    return Database.from_config(config)
