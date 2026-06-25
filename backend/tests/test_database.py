import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.db import Database, create_database
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


if __name__ == "__main__":
    unittest.main()
