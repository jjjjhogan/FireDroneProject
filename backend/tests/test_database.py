import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.db import Database, create_database
from app.db.connection import _ConnectionProxy
from app.ops.store import OperationsStore
from app.accounts.store import AccountStore


class DatabaseConfigTest(unittest.TestCase):
    def test_sqlite_fallback_when_database_url_missing(self):
        db = create_database({"APP_DATABASE_FILE": "instance/test.sqlite3"})
        self.assertEqual(db.engine, "sqlite")

    def test_postgres_when_database_url_set(self):
        db = create_database(
            {"DATABASE_URL": "postgresql://user:pass@localhost:5432/testdb"}
        )
        self.assertEqual(db.engine, "postgresql")

    def test_postgres_url_normalizes_postgres_scheme(self):
        db = Database(database_url="postgres://user:pass@localhost/db")
        self.assertEqual(db.database_url, "postgresql://user:pass@localhost/db")


class SqliteStoreIntegrationTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.db_path = Path(self.temp_dir.name) / "shared.sqlite3"
        self.db = Database(sqlite_path=str(self.db_path))

    def test_operations_and_accounts_share_sqlite_file(self):
        ops = OperationsStore(database=self.db)
        accounts = AccountStore(database=self.db)

        ops.record_audit(
            actor="tester",
            role="operator",
            action="Smoke test",
            target_id="db",
            details="sqlite shared db",
        )
        token, account = accounts.register(
            {
                "email": "ops@test.example",
                "password": "password123",
                "displayName": "Ops Tester",
            }
        )

        self.assertTrue(token.startswith("acct_"))
        self.assertEqual(account["email"], "ops@test.example")
        self.assertEqual(len(ops.list_audit()), 1)


class ConnectionProxyTest(unittest.TestCase):
    def test_postgres_executemany_uses_execute_when_driver_lacks_executemany(self):
        class FakeCursor:
            rowcount = 1

        class FakePostgresConnection:
            def __init__(self):
                self.executed = []

            def execute(self, sql, params=()):
                self.executed.append((sql, params))
                return FakeCursor()

        connection = FakePostgresConnection()
        proxy = _ConnectionProxy(connection, "postgresql")

        proxy.executemany(
            "insert into safety_checklist (key, status) values (?, ?)",
            [
                ("geofence", "pending"),
                ("remoteId", "verified"),
            ],
        )

        self.assertEqual(len(connection.executed), 2)
        self.assertEqual(
            connection.executed[0][0],
            "insert into safety_checklist (key, status) values (%s, %s)",
        )
        self.assertEqual(connection.executed[0][1], ("geofence", "pending"))
        self.assertEqual(connection.executed[1][1], ("remoteId", "verified"))


if __name__ == "__main__":
    unittest.main()
