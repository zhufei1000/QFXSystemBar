"""Check the development archive and keep both package filters in agreement."""
import importlib.util
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("build_release_zip", ROOT / "tests/build_release_zip.py")
package = importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)


class ReleasePackagingTest(unittest.TestCase):
    def test_runtime_contents_and_packager_parity(self):
        sources = [path for addon in package.ADDON_DIRS for path in (ROOT / addon).rglob("*") if path.is_file()]
        expected = {path.relative_to(ROOT).as_posix() for path in sources if package.is_runtime_file(path)}
        excluded = {path.relative_to(ROOT).as_posix() for path in sources if not package.is_runtime_file(path)}
        metadata = (ROOT / ".pkgmeta").read_text(encoding="utf-8-sig")
        ignored = {line.strip()[2:] for line in metadata.splitlines() if line.strip().startswith("- ")}
        self.assertEqual(excluded, ignored & {path.relative_to(ROOT).as_posix() for path in sources})
        self.assertTrue(excluded)
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "nested/dev.zip"
            count, size = package.build_package(output)
            self.assertEqual(count, len(expected))
            self.assertGreater(size, 0)
            with zipfile.ZipFile(output) as archive:
                self.assertIsNone(archive.testzip())
                self.assertEqual(set(archive.namelist()), expected)
                for path in sources:
                    if path.suffix.lower() in {".lua", ".toc"}:
                        self.assertIn(path.relative_to(ROOT).as_posix(), expected)
                self.assertIn("QFXSystemBar_MeetingStone/LycheeGroupBridge.lua", expected)
                self.assertIn("QFXSystemBar/Media/MicroMenu/MeetingStone.tga", expected)
                self.assertIn("QFXSystemBar/Media/MicroMenu/Lucide/MeetingStone.blp", expected)

    def test_existing_archive_is_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "existing.zip"
            output.write_bytes(b"existing release")
            with self.assertRaises(FileExistsError):
                package.build_package(output)
            self.assertEqual(output.read_bytes(), b"existing release")


if __name__ == "__main__":
    unittest.main()
