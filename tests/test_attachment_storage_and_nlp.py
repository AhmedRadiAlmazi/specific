"""
Phase 6 Attachment Storage, Arabic NLP Normalizer, and Offline Resilience Test Suite — مشروع «مُعين» (Mouin)
"""

import unittest
import os
import shutil
import tempfile

from backend.app.infrastructure.storage.attachment_storage import AttachmentStorageService
from backend.app.domain.services.arabic_normalizer import (
    normalize_arabic, strip_tashkeel, strip_tatweel, normalize_hamzas, normalize_endings, tokenize_search_query
)

class TestAttachmentStorageAndNLP(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.mkdtemp(prefix="mouin_test_storage_")
        self.storage = AttachmentStorageService(base_storage_dir=self.test_dir)
        self.workspace_id = "018e3a2b-0002-7000-8000-000000000002"

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_attachment_storage_lifecycle_and_sha256(self):
        sample_data = b"MOUIN_VOICE_RECORDING_BINARY_DATA_TEST_12345"
        path, checksum, size, mime = self.storage.save_file(
            workspace_id=self.workspace_id,
            file_name="recording.m4a",
            file_bytes=sample_data
        )

        self.assertTrue(os.path.exists(path))
        self.assertEqual(size, len(sample_data))
        self.assertEqual(len(checksum), 64)  # Valid SHA-256 hex string

        # Read file back
        read_bytes = self.storage.read_file(path)
        self.assertEqual(read_bytes, sample_data)

        # Delete file
        deleted = self.storage.delete_file(path)
        self.assertTrue(deleted)
        self.assertFalse(os.path.exists(path))

    def test_attachment_storage_path_traversal_guard(self):
        malicious_path = os.path.join(self.test_dir, "..", "system.key")
        with self.assertRaises(FileNotFoundError):
            self.storage.read_file(malicious_path)

    def test_arabic_nlp_tashkeel_and_tatweel_stripping(self):
        text_with_tashkeel = "مُعِيْنٌ — مُسَاعِدُكَ الشَّخْصِيُّ"
        stripped = strip_tashkeel(text_with_tashkeel)
        self.assertEqual(stripped, "معين — مساعدك الشخصي")

        text_with_tatweel = "مــــعـــيـــن"
        self.assertEqual(strip_tatweel(text_with_tatweel), "معين")

    def test_arabic_nlp_hamza_and_ending_normalization(self):
        # Hamza variants
        self.assertEqual(normalize_hamzas("أحمد وإبراهيم وآدم"), "احمد وابراهيم وادم")
        self.assertEqual(normalize_hamzas("مسؤولية"), "مسوولية")
        self.assertEqual(normalize_hamzas("عائلة"), "عايلة")

        # Word endings (ة -> ه, ى -> ي)
        self.assertEqual(normalize_endings("مكتبة مستشفى"), "مكتبه مستشفي")

    def test_arabic_nlp_full_normalization_and_tokenization(self):
        raw_text = "  شِرَاءُ   أَدْوِيَةٍ مِنَ الصَّيْدَلِيَّةِ  "
        normalized = normalize_arabic(raw_text)
        self.assertEqual(normalized, "شراء ادويه من الصيدليه")

        tokens = tokenize_search_query(raw_text)
        self.assertEqual(tokens, ["شراء", "ادويه", "من", "الصيدليه"])

if __name__ == "__main__":
    unittest.main()
