"""
Architecture Guard Tests — مشروع «مُعين» (Mouin)
Strict static inspections preventing framework & SQL leakage into pure Domain and Application layers.
"""

import unittest
import os
import re

class TestArchitectureGuard(unittest.TestCase):
    def test_domain_purity_no_framework_or_db_leakage(self):
        domain_dir = "backend/app/domain"
        forbidden_tokens = ["fastapi", "starlette", "sqlite3", "psycopg2", "psycopg", "sqlalchemy", "HTTPException"]
        for root, _, files in os.walk(domain_dir):
            for f in files:
                if f.endswith(".py"):
                    fpath = os.path.join(root, f)
                    with open(fpath, "r", encoding="utf-8") as fp:
                        content = fp.read()
                    for token in forbidden_tokens:
                        self.assertNotIn(
                            f"import {token}", content,
                            f"Architecture Violation: Domain file {fpath} must NOT import {token}"
                        )
                        self.assertNotIn(
                            f"from {token}", content,
                            f"Architecture Violation: Domain file {fpath} must NOT import from {token}"
                        )

    def test_application_purity_no_http_leakage(self):
        app_dir = "backend/app/application"
        forbidden_tokens = ["fastapi", "starlette", "HTTPException"]
        for root, _, files in os.walk(app_dir):
            for f in files:
                if f.endswith(".py"):
                    fpath = os.path.join(root, f)
                    with open(fpath, "r", encoding="utf-8") as fp:
                        content = fp.read()
                    for token in forbidden_tokens:
                        self.assertNotIn(
                            f"import {token}", content,
                            f"Architecture Violation: Application file {fpath} must NOT import {token}"
                        )
                        self.assertNotIn(
                            f"from {token}", content,
                            f"Architecture Violation: Application file {fpath} must NOT import from {token}"
                        )

    def test_routers_no_raw_sql_execution(self):
        routers_dir = "backend/app/presentation/api/routers"
        forbidden_sql = [
            "SELECT ", "INSERT INTO ", "UPDATE ", "DELETE FROM ",
            "cursor.execute", ".execute("
        ]
        for root, _, files in os.walk(routers_dir):
            for f in files:
                if f.endswith(".py"):
                    fpath = os.path.join(root, f)
                    with open(fpath, "r", encoding="utf-8") as fp:
                        content = fp.read()
                    for sql in forbidden_sql:
                        self.assertNotIn(
                            sql, content,
                            f"Architecture Violation: Router {fpath} must NOT execute raw SQL directly! Found: {sql}"
                        )

if __name__ == '__main__':
    unittest.main()
