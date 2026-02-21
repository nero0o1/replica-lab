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
from emitters.vanilla_web_emitter import VanillaWebEmitter

class MassConverter:
    def __init__(self, input_dir: str, output_dir: str):
        self.input_dir = input_dir
        self.output_dir = output_dir
        self.stats = {
            "total": 0,
            "success": 0,
            "failed": 0,
            "start_time": time.time(),
            "errors": []
        }

    def run(self):
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)

        files = [f for f in os.listdir(self.input_dir) if f.endswith('.edt')]
        self.stats["total"] = len(files)

        print(f"--- REPLICA EDITOR: BATCH CONVERSION STARTED ---")
        print(f"Scanning directory: {self.input_dir}")
        print(f"Found {self.stats['total']} files.\n")

        for filename in files:
            input_path = os.path.join(self.input_dir, filename)
            output_name = filename.replace('.edt', '.html')
            output_path = os.path.join(self.output_dir, output_name)

            try:
                # 1. Parsing Simulation (Neutral AST instantiation)
                # In production, this would call ImporterV2 or ImporterV3
                doc = self._mock_import(filename)
                
                # 2. Emission
                emitter = VanillaWebEmitter()
                html = emitter.emit(doc)
                
                with open(output_path, "w", encoding="utf-8") as f:
                    f.write(html)
                
                self.stats["success"] += 1
                print(f"[OK] {filename} -> {output_name}")

            except Exception as e:
                self.stats["failed"] += 1
                error_info = {
                    "file": filename,
                    "error": str(e),
                    "traceback": traceback.format_exc()
                }
                self.stats["errors"].append(error_info)
                print(f"[FAIL] {filename}: {str(e)}")

        self._finalize()

    def _mock_import(self, filename: str) -> MvDocument:
        """Simulates importing logic. Crashes if filename contains 'corrupt'."""
        if "corrupt" in filename.lower():
            raise ValueError("Corrupted file structure detected (Mock Validation Failure).")
        
        doc = MvDocument(f"Form: {filename}")
        layout = MvLayout()
        doc.layouts.append(layout)
        
        f = MvField()
        f.identifier, f.name, f.vis_type_identifier = "FIELD_A", "Sample Field", "TEXT"
        layout.fields.append(f)
        
        return doc

    def _finalize(self):
        duration = time.time() - self.stats["start_time"]
        
        # Save Error Report
        with open("error_report.json", "w") as f:
            json.dump(self.stats["errors"], f, indent=4)

        print("\n" + "="*40)
        print("CONVERSION SUMMARY")
        print("="*40)
        print(f"Total Processed: {self.stats['total']}")
        print(f"Success items:   {self.stats['success']}")
        print(f"Failed items:    {self.stats['failed']}")
        print(f"Duration:        {duration:.2f} seconds")
        print(f"Error Report:    error_report.json")
        print("="*40)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Replica Editor Mass Converter")
    parser.add_argument("--input", required=True, help="Input directory (.edt files)")
    parser.add_argument("--output", required=True, help="Output directory (HTML files)")
    
    args = parser.parse_args()
    
    converter = MassConverter(args.input, args.output)
    converter.run()
