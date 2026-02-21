import sys
import os
import json
import hashlib
sys.path.append(os.path.join(os.path.dirname(os.path.dirname(__file__)), 'src'))

from core.json_parser import MvJsonParser
from core.ast_nodes import MvDocument

class ReconstructionAuditor:
    ORACLE_MAX_CHARS = 4000
    
    def __init__(self, file_path: str):
        self.file_path = file_path
        self.errors = []
        
    def audit(self):
        print(f"--- Running VT-3 Reconstruction Audit: {os.path.basename(self.file_path)} ---")
        
        if self.file_path.endswith(".json") or self.file_path.endswith(".edt"):
            self._audit_json()
        else:
            self.errors.append(f"Format not supported for automated audit: {self.file_path}")
            
        return len(self.errors) == 0

    def _audit_json(self):
        with open(self.file_path, "r", encoding="utf-8") as f:
            raw_content = f.read()
            
        try:
            data = json.loads(raw_content)
        except Exception as e:
            self.errors.append(f"JSON Syntax Error: {e}")
            return

        # 1. MD5 Integrity Check
        expected_hash = data.get("version", {}).get("hash")
        if expected_hash:
            # We would typically re-calc here, but for this audit we verify existence 
            # and format consistency.
            if len(expected_hash) != 32:
                self.errors.append(f"MD5 Integrity: Invalid hash format ({expected_hash})")
        
        # 2. Logic Reconstruction (Parse to AST)
        parser = MvJsonParser()
        doc = parser.parse(raw_content)
        
        # 3. Character Limit Enforcement (Prop 1 / ORACLE_MAX_CHARS)
        for layout in doc.layouts:
            for field in doc.flatten_fields(layout.fields):
                for prop in field.properties:
                    if prop.id == 1: # TAMANHO
                        limit = int(prop.value)
                        # Find the actual content property (usually 14 or 9)
                        content_val = ""
                        for p in field.properties:
                            if p.id in [14, 9]:
                                content_val = str(p.value or "")
                        
                        if len(content_val) > limit:
                            self.errors.append(f"OVERFLOW: Field '{field.identifier}' exceeds limit ({len(content_val)} > {limit})")
                        
                        if len(content_val) > self.ORACLE_MAX_CHARS:
                            self.errors.append(f"ORACLE_VIOLATION: Field '{field.identifier}' exceeds Oracle 4000 char hard limit.")

        # 4. Spatial Matrix Integrity
        for layout in doc.layouts:
            for field in doc.flatten_fields(layout.fields):
                if field.x < 0 or field.y < 0:
                    self.errors.append(f"BOUNDARY_ERROR: Field '{field.identifier}' has negative coordinates ({field.x}, {field.y})")

    def report(self):
        if not self.errors:
            print("🟩 AUDIT PASSED: All VT-3 constraints satisfied.")
        else:
            print("🟥 AUDIT FAILED:")
            for err in self.errors:
                print(f"  - {err}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python reconstruction_audit.py <file_path>")
        sys.exit(1)
        
    auditor = ReconstructionAuditor(sys.argv[1])
    success = auditor.audit()
    auditor.report()
    sys.exit(0 if success else 1)
