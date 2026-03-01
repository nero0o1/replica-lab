
import os
import xml.etree.ElementTree as ET
import base64
import json
import hashlib
import re

def get_md5(text):
    if text is None: return "null"
    return hashlib.md5(text.encode('utf-8')).hexdigest()

def analyze_edt_deep(file_path):
    print(f"\n--- Deep Diving into EDT: {os.path.basename(file_path)} ---")
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            if not content.strip().startswith('{'):
                print("Not a JSON EDT (probably version or legacy).")
                return

            data = json.loads(content)
            # Scan for hash consistency
            hashes_found = []
            
            def scan_obj(obj):
                if isinstance(obj, dict):
                    if 'value' in obj and 'hash' in obj:
                        val = obj['value']
                        h = obj['hash']
                        calc = get_md5(str(val)) if val is not None else get_md5("")
                        # MD5 for boolean 'true' is b326...
                        # MD5 for string 'true' is also b326...
                        hashes_found.append((val, h, calc == h))
                    for k, v in obj.items():
                        scan_obj(v)
                elif isinstance(obj, list):
                    for item in obj:
                        scan_obj(item)

            scan_obj(data)
            
            # Summary of hashes
            matches = [h for h in hashes_found if h[2]]
            mismatches = [h for h in hashes_found if not h[2] and h[1] is not None]
            
            print(f"Hashes scanned: {len(hashes_found)}")
            print(f"Direct MD5 Matches: {len(matches)}")
            print(f"Mismatches: {len(mismatches)}")
            
            if mismatches:
                print("First 3 Mismatches (Potential Salt/Algorithm change):")
                for val, h, _ in mismatches[:3]:
                    print(f"  Value: {str(val)[:50]}... \n  Expected Hash: {h} \n  Standard MD5: {get_md5(str(val))}")

            # Scan for "Poison Pills" - Hardcoded IDs or paths
            if 'multi_empresa' in content.lower():
                print("Presence of 'multi_empresa' detected.")
            
            # Check for binary/large content markers
            if 'base64' in content.lower() or 'data:image' in content.lower():
                print("Embedded assets (images/base64) detected.")

    except Exception as e:
        print(f"Error: {e}")

def analyze_burp_xml_all(path):
    print(f"\n--- Forensic Scan of Burp Export: {os.path.basename(path)} ---")
    try:
        # Use iterparse for large files
        context = ET.iterparse(path, events=('end',))
        unique_methods = set()
        suspicious_headers = set()
        
        count = 0
        for event, elem in context:
            if elem.tag == 'item':
                count += 1
                url = elem.find('url').text
                method = elem.find('method').text
                unique_methods.add(f"{method} {url}")
                
                # Check headers for interesting tokens
                request_el = elem.find('request')
                if request_el is not None:
                    text = request_el.text
                    if request_el.get('base64') == 'true':
                        raw_req = base64.b64decode(text).decode('utf-8', errors='ignore')
                    else:
                        raw_req = text
                    
                    # Scan for "Chave" and "Volta" or equivalents
                    if any(x in raw_req.lower() for x in ['authorization', 'token', 'cookie', 'session', 'x-']):
                        # Just count headers for now
                        pass
                
                elem.clear() # Free memory
        print(f"Total HTTP items scanned: {count}")
    except Exception as e:
        print(f"Error parsing XML: {e}")

# Targeting AMB and the large XML
analyze_edt_deep(r'j:\replica_lab\burp_analise\AMB_unzipped\5.documents_ficha_ambulatorial_14.edt')
analyze_edt_deep(r'j:\replica_lab\burp_analise\AMB_unzipped\4.footers_RODAPE_SES_GO1.edt')
analyze_burp_xml_all(r'j:\replica_lab\burp_analise\save_all_documento_clinico_V3.xml')
