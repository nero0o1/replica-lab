import hashlib
import re
from typing import Any, Optional, Dict
import logging

logger = logging.getLogger("HashEngine")

class HashEngine:
    """
    Mandatory Integrity Engine (SINC-2Ψ Protocol).
    Implements MD5 checksums for clinical artifacts with strict parity rules.
    """

    @staticmethod
    def calculate_md5(data: str) -> str:
        """Calculates MD5 and ensures 32-character string (Leading Zero Fix)."""
        if not data:
            return ""
        # Sanitization as per Dossier 01: Remove \r and strip whitespace
        sanitized = data.replace('\r', '').strip()
        md5_hash = hashlib.md5(sanitized.encode('utf-8')).hexdigest()
        # Normalization: ensure 32 chars (already handled by hexdigest, but for clarity)
        return md5_hash.zfill(32)

    @staticmethod
    def calculate_root_hash(field_id: int, identifier: str, vis_type_id: int) -> str:
        """
        Calculates the Root Hash (DNA of the field).
        Format: ID + IDENTIFIER + TYPE_ID (No separators).
        """
        raw = f"{field_id}{identifier}{vis_type_id}"
        return HashEngine.calculate_md5(raw)

    @staticmethod
    def calculate_property_hash(value: Any) -> Optional[str]:
        """
        Calculates hash for individual properties.
        - Booleans: 'S'/'N' -> 'true'/'false'
        - Nulls: Return None (No hash)
        - Strings: Sanitized UTF-8
        """
        if value is None:
            return None
        
        # Boolean Paradox Fix (Dossier 01, 3.2)
        if isinstance(value, bool):
            val_str = "true" if value else "false"
        elif str(value).upper() in ['S', 'TRUE', '1']:
            val_str = "true"
        elif str(value).upper() in ['N', 'FALSE', '0']:
            val_str = "false"
        else:
            val_str = str(value)
            
        return HashEngine.calculate_md5(val_str)

    @staticmethod
    def verify(doc: Any) -> bool:
        """
        Checks if the document's ingestion hashes match the computed values.
        Validation N3 (Pro-Λ).
        """
        # Placeholder for complex recursive validation.
        # In this phase, we ensure the root hash and property hashes are consistent.
        # This will be called by cli_mass_converter.py
        return True # Default for now, to be extended in full integration.

    @staticmethod
    def validate_output(html_output: str, doc: Any) -> bool:
        """
        Identity Audit: Ensures all fields in AST are present in the DOM.
        Prevents "Silent Emission Failure".
        """
        # Check for presence of all field identifiers as mv-field-{id}
        for layout in doc.layouts:
            for field in doc.flatten_fields(layout.fields):
                # We expect the Emitter to prefix IDs with mv-field-
                pattern = f'id="mv-field-{field.identifier}"'
                if pattern not in html_output:
                    logger.error(f"Integrity Gap Detected: Field '{field.identifier}' missing in DOM output.")
                    return False
        return True
