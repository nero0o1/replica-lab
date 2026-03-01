import json
import os
import shutil

def sanitize_node(node):
    if isinstance(node, list):
        for item in node:
            sanitize_node(item)
        return
    
    if not isinstance(node, dict):
        return

    # 1. Nullify Primary Keys
    pk_fields = ["code", "documentId", "versionId", "layoutId", "id", "cdDocumento", "cdEditorDocumento"]
    for field in pk_fields:
        if field in node:
            node[field] = None

    # 2. Nullify Hashes to force server-side recalculation
    if "hash" in node:
        node["hash"] = None

    # 3. Neutralize Group/Folder
    if "groupId" in node:
        node["groupId"] = None
    if "group" in node:
        if isinstance(node["group"], dict):
            if "id" in node["group"]:
                node["group"]["id"] = None

    # 4. Correct Metadata (The "imported" fix)
    # The server fails with NullPointerException if propertyDocumentValues is missing 
    # when it tries to set "imported" = true.
    if "propertyDocumentValues" in node:
        # We preserve the structure but force the imported/migrated flags
        props = node["propertyDocumentValues"]
        has_imported = False
        has_migrated = False
        for p in props:
            if p.get("property", {}).get("identifier") == "importado":
                p["value"] = "true"
                has_imported = True
            if p.get("property", {}).get("identifier") == "migrado":
                p["value"] = "true"
                has_migrated = True
        
        # If missing, add them (CRITICAL)
        if not has_imported:
            props.append({
                "property": {"id": 33, "identifier": "importado"},
                "value": "true"
            })
        if not has_migrated:
            props.append({
                "property": {"id": 34, "identifier": "migrado"},
                "value": "true"
            })

    # Recurse
    for key, value in node.items():
        if isinstance(value, (dict, list)):
            sanitize_node(value)

def process_file(source_path, output_path):
    print(f"Processing {source_path}...")
    try:
        with open(source_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        sanitize_node(data)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        print(f"  Success: {output_path}")
    except Exception as e:
        print(f"  Error processing {source_path}: {e}")

if __name__ == "__main__":
    # Source identifiers and their names
    sources = [
        (r"j:\replica_lab\temp_repack\APAC_REV_2026-unzip\document.json", "APAC_REV_2026"),
        (r"j:\replica_lab\temp_repack\AIH_SES_REV_2026-unzip\document.json", "AIH_SES_REV_2026"),
        (r"j:\replica_lab\temp_repack\ficha_ambulatorial_1_REV_2026-unzip\document.json", "ficha_ambulatorial_1_REV_2026")
    ]
    
    target_dir = r"j:\replica_lab\temp_pack_v3"
    output_dir = r"j:\replica_lab\flow_forms_ready"
    burp_ref_dir = r"j:\replica_lab\burp_analise\save_documento_clinico_V3"
    
    # Version discovered via Burp Analysis
    version = "2025.1.0-RC25"
    
    os.makedirs(target_dir, exist_ok=True)
    os.makedirs(output_dir, exist_ok=True)

    for src, name in sources:
        if not os.path.exists(src):
            print(f"Source not found: {src}")
            continue
            
        staging = os.path.join(target_dir, name)
        if os.path.exists(staging):
            shutil.rmtree(staging)
        os.makedirs(staging, exist_ok=True)
        
        # 1. Version file (Sequence 1)
        with open(os.path.join(staging, "1.editor.version.edt"), 'w', encoding='utf-8') as f:
            f.write(version)
            
        # 2. Reference Headers and Footers (Sequence 3 and 4)
        # These are usually required for the package to be considered complete
        header_src = os.path.join(burp_ref_dir, "3.headers_CABECALHO_SES_GO1.edt")
        footer_src = os.path.join(burp_ref_dir, "4.footers_RODAPE_SES_GO1.edt")
        
        if os.path.exists(header_src):
            shutil.copy(header_src, os.path.join(staging, "3.headers_CABECALHO_SES_GO1.edt"))
        if os.path.exists(footer_src):
            shutil.copy(footer_src, os.path.join(staging, "4.footers_RODAPE_SES_GO1.edt"))
            
        # 3. The Document Payload (Sequence 5)
        out_payload = os.path.join(staging, f"5.documents_{name}.edt")
        process_file(src, out_payload)

        # 4. Create ZIP
        zip_base = os.path.join(output_dir, name)
        if os.path.exists(zip_base + ".zip"):
            os.remove(zip_base + ".zip")
        
        shutil.make_archive(zip_base, 'zip', staging)
        print(f"  Package Created: {name}.zip")
