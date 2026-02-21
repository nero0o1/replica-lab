import os
import sys
import json
import time
import argparse
import traceback
from typing import Dict, List

# Add src to path
sys.path.append(os.path.join(os.getcwd(), 'src'))

from core.ast_nodes import MvDocument, MvLayout, MvField
from core.hash_engine import HashEngine
from emitters.vanilla_web_emitter import VanillaWebEmitter

class MassConverter:
    """
    Forensic Batch Engine (Operation Crucible).
    Implements mandatory I/O, hash gating, and ledger generation.
    """
    def __init__(self, input_dir: str, output_dir: str):
        self.input_dir = input_dir
        self.output_dir = output_dir
        self.ledger = {
            "session_id": f"CRUCIBLE_{int(time.time())}",
            "start_time": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "stats": {"total": 0, "success": 0, "integrity_failed": 0, "parsing_failed": 0, "collisions": 0},
            "artifacts": []
        }

    def run(self):
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)

        files = [f for f in os.listdir(self.input_dir) if f.endswith('.edt')]
        self.ledger["stats"]["total"] = len(files)

        print(f"--- REPLICA EDITOR: FORENSIC BATCH STARTED ---")
        
        for filename in files:
            input_path = os.path.join(self.input_dir, filename)
            output_name = filename.replace('.edt', '.html')
            output_path = os.path.join(self.output_dir, output_name)
            
            artifact_entry = {
                "input": filename,
                "output": output_name,
                "status": "PENDING",
                "integrity_gate": "NOT_STARTED",
                "layout_collision": False
            }

            try:
                # 1. Ingestion (Simulation for Phase 1)
                doc = self._mock_import(filename)
                
                # Phase 1 Integrity: Check Ingestion Hash
                if not HashEngine.verify(doc):
                    artifact_entry["status"] = "ABORTED"
                    artifact_entry["integrity_gate"] = "FAILED_INGESTION"
                    self.ledger["stats"]["integrity_failed"] += 1
                    continue

                # 2. Emission
                emitter = VanillaWebEmitter()
                html_output = emitter.emit(doc)
                audit = emitter.get_audit_result()
                
                artifact_entry["layout_collision"] = audit.get("has_layout_collision", False)
                if artifact_entry["layout_collision"]:
                    self.ledger["stats"]["collisions"] += 1

                # 3. Post-Emission Integrity Gate
                if not HashEngine.validate_output(html_output, doc):
                    artifact_entry["status"] = "ABORTED"
                    artifact_entry["integrity_gate"] = "FAILED_EMISSION_PARITY"
                    self.ledger["stats"]["integrity_failed"] += 1
                    continue

                # 4. Mandatory File I/O
                with open(output_path, "w", encoding="utf-8") as f:
                    f.write(html_output)
                
                artifact_entry["status"] = "SUCCESS"
                artifact_entry["integrity_gate"] = "PASSED"
                self.ledger["stats"]["success"] += 1

            except Exception as e:
                self.ledger["stats"]["parsing_failed"] += 1
                artifact_entry["status"] = "FAILED"
                artifact_entry["error"] = str(e)
                artifact_entry["trace"] = traceback.format_exc()

            self.ledger["artifacts"].append(artifact_entry)
            status_symbol = "[OK]" if artifact_entry["status"] == "SUCCESS" else "[FAIL]"
            print(f"{status_symbol} {filename} -> {output_name} (MD5 Gate: {artifact_entry['integrity_gate']})")

        self._finalize()

    def _mock_import(self, filename: str) -> MvDocument:
        """Simulates MvDocument ingestion for batch testing."""
        doc = MvDocument(f"Form_{filename}")
        layout = MvLayout()
        doc.layouts.append(layout)
        
        f = MvField()
        f.identifier, f.name, f.vis_type_identifier = "FIELD_A", "Sample Name", "TEXT"
        f.x, f.y, f.width, f.height = 10, 10, 200, 30
        layout.fields.append(f)
        
        # Force a collision if filename contains 'collision'
        if "collision" in filename.lower():
            f2 = MvField()
            f2.identifier, f2.name, f2.vis_type_identifier = "FIELD_B", "Overlapping Field", "TEXT"
            f2.x, f2.y, f2.width, f2.height = 15, 15, 200, 30
            layout.fields.append(f2)

        return doc

    def _finalize(self):
        self.ledger["end_time"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        ledger_path = os.path.join(self.output_dir, "execution_ledger.json")
        with open(ledger_path, "w") as f:
            json.dump(self.ledger, f, indent=4)

        print("\n" + "="*40)
        print("CONVERSION SUMMARY (FORENSIC)")
        print("="*40)
        print(f"Total: {self.ledger['stats']['total']}")
        print(f"Success: {self.ledger['stats']['success']}")
        print(f"Integrity Fails: {self.ledger['stats']['integrity_failed']}")
        print(f"Parsing Fails: {self.ledger['stats']['parsing_failed']}")
        print(f"Collisions: {self.ledger['stats']['collisions']}")
        print(f"Ledger: {ledger_path}")
        print("="*40)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Crucible Batch Engine")
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    
    converter = MassConverter(args.input, args.output)
    converter.run()
