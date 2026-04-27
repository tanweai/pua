import pathlib
import subprocess
import sys
import tempfile
import unittest
import json
import os


REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]
REGISTRY_PATH = REPO_ROOT / "codex" / "subcommands.json"
SCRIPT_PATH = REPO_ROOT / "scripts" / "codex_subcommands.py"


class CodexSubcommandParityTest(unittest.TestCase):
    def _extract_frontmatter_value(self, skill_path: pathlib.Path, field: str) -> str:
        for line in skill_path.read_text().splitlines():
            if line.startswith(f"{field}:"):
                return line.split(":", 1)[1].strip().strip("\"'")
        raise AssertionError(f"Missing {field} frontmatter in {skill_path}")

    def test_registry_file_exists(self) -> None:
        self.assertTrue(REGISTRY_PATH.is_file(), "codex/subcommands.json must exist")

    def test_every_export_entry_has_canonical_target(self) -> None:
        registry = json.loads(REGISTRY_PATH.read_text())
        for entry in registry["install"]:
            self.assertIn("target", entry, entry["name"])

    def test_registry_matches_codex_exports(self) -> None:
        registry = json.loads(REGISTRY_PATH.read_text())
        install_by_source = {entry["source"]: entry for entry in registry["install"]}

        exported_skill_files = sorted((REPO_ROOT / "codex").glob("*/SKILL.md"))
        exported_skill_files.extend(sorted((REPO_ROOT / "codex" / "skills").glob("*/SKILL.md")))

        expected_sources = {
            str(skill_path.relative_to(REPO_ROOT).parent) for skill_path in exported_skill_files
        }
        self.assertSetEqual(expected_sources, set(install_by_source))

        for skill_path in exported_skill_files:
            source = str(skill_path.relative_to(REPO_ROOT).parent)
            self.assertEqual(
                self._extract_frontmatter_value(skill_path, "name"),
                install_by_source[source]["name"],
                source,
            )

    def test_registry_uses_codex_only_export_paths(self) -> None:
        registry = json.loads(REGISTRY_PATH.read_text())
        self.assertTrue(registry["prompt"]["source"].startswith("codex/"))
        for entry in registry["install"]:
            self.assertTrue(entry["source"].startswith("codex/"), entry)

    def test_export_descriptions_match_canonical_targets(self) -> None:
        registry = json.loads(REGISTRY_PATH.read_text())
        for entry in registry["install"]:
            source_path = REPO_ROOT / entry["source"] / "SKILL.md"
            target_path = REPO_ROOT / entry["target"] / "SKILL.md"
            self.assertEqual(
                self._extract_frontmatter_value(source_path, "description"),
                self._extract_frontmatter_value(target_path, "description"),
                entry["name"],
            )

    def test_non_alias_exports_reuse_canonical_skill_file(self) -> None:
        registry = json.loads(REGISTRY_PATH.read_text())
        for entry in registry["install"]:
            source_path = REPO_ROOT / entry["source"] / "SKILL.md"
            target_path = REPO_ROOT / entry["target"] / "SKILL.md"
            canonical_name = self._extract_frontmatter_value(target_path, "name")
            if entry["name"] != canonical_name:
                continue
            self.assertTrue(source_path.is_symlink(), entry["name"])
            self.assertEqual(source_path.resolve(), target_path.resolve(), entry["name"])

    def test_non_alias_exports_use_relative_symlinks(self) -> None:
        registry = json.loads(REGISTRY_PATH.read_text())
        for entry in registry["install"]:
            source_path = REPO_ROOT / entry["source"] / "SKILL.md"
            target_path = REPO_ROOT / entry["target"] / "SKILL.md"
            canonical_name = self._extract_frontmatter_value(target_path, "name")
            if entry["name"] != canonical_name:
                continue

            symlink_target = os.readlink(source_path)
            self.assertFalse(pathlib.Path(symlink_target).is_absolute(), entry["name"])

    def test_shared_skill_names_remain_unchanged(self) -> None:
        expected = {
            "p7": "p7",
            "p9": "p9",
            "p10": "p10",
            "pro": "pro",
            "yes": "yes",
            "mama": "mama",
            "shot": "shot",
            "pua-loop": "pua-loop",
        }

        for directory, expected_name in expected.items():
            content = (REPO_ROOT / "skills" / directory / "SKILL.md").read_text()
            actual_name = None
            for line in content.splitlines():
                if line.startswith("name:"):
                    actual_name = line.split(":", 1)[1].strip().strip("\"'")
                    break
            self.assertEqual(expected_name, actual_name, directory)

    def test_install_and_uninstall_round_trip(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            codex_home = pathlib.Path(temp_dir)
            registry = json.loads(REGISTRY_PATH.read_text())

            subprocess.run(
                [sys.executable, str(SCRIPT_PATH), "install", "--codex-home", str(codex_home)],
                check=True,
                cwd=REPO_ROOT,
            )
            manifest_path = codex_home / ".pua-codex-install.json"
            self.assertTrue(manifest_path.is_file())

            manifest = json.loads(manifest_path.read_text())
            self.assertNotIn("repo_root", manifest)
            self.assertEqual(manifest["prompts"], ["prompts/pua.md"])

            prompt_path = codex_home / "prompts" / "pua.md"
            self.assertTrue(prompt_path.is_symlink())
            self.assertFalse(pathlib.Path(os.readlink(prompt_path)).is_absolute())

            expected_skill_paths = []
            for entry in registry["install"]:
                source_dir = pathlib.Path(entry["source"])
                destination = codex_home / "skills" / source_dir.name
                expected_skill_paths.append(f"skills/{source_dir.name}")
                self.assertTrue(destination.is_symlink(), source_dir.name)
                self.assertFalse(pathlib.Path(os.readlink(destination)).is_absolute(), source_dir.name)

            self.assertEqual(manifest["skills"], expected_skill_paths)

            subprocess.run(
                [sys.executable, str(SCRIPT_PATH), "uninstall", "--codex-home", str(codex_home)],
                check=True,
                cwd=REPO_ROOT,
            )
            self.assertFalse((codex_home / ".pua-codex-install.json").exists())
            self.assertFalse((codex_home / "skills").exists())
            self.assertFalse((codex_home / "prompts").exists())

    def test_install_rewrites_absolute_symlinks_to_relative(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            codex_home = pathlib.Path(temp_dir)
            skill_destination = codex_home / "skills" / "pua"
            prompt_destination = codex_home / "prompts" / "pua.md"

            skill_destination.parent.mkdir(parents=True, exist_ok=True)
            prompt_destination.parent.mkdir(parents=True, exist_ok=True)

            skill_destination.symlink_to(REPO_ROOT / "codex" / "pua")
            prompt_destination.symlink_to(REPO_ROOT / "codex" / "prompts" / "pua.md")

            self.assertTrue(pathlib.Path(os.readlink(skill_destination)).is_absolute())
            self.assertTrue(pathlib.Path(os.readlink(prompt_destination)).is_absolute())

            subprocess.run(
                [sys.executable, str(SCRIPT_PATH), "install", "--codex-home", str(codex_home)],
                check=True,
                cwd=REPO_ROOT,
            )

            self.assertFalse(pathlib.Path(os.readlink(skill_destination)).is_absolute())
            self.assertFalse(pathlib.Path(os.readlink(prompt_destination)).is_absolute())


if __name__ == "__main__":
    unittest.main()
