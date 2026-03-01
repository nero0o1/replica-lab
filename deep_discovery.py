
import os
import xml.etree.ElementTree as ET
import base64
import urllib.parse
import re

def analyze_burp_deep(path):
    print(f"--- Deep Analysis: {path} ---")
    try:
        tree = ET.parse(path)
        root = tree.getroot()
        items = root.findall('item')
        
        print(f"Total entries: {len(items)}")
        
        unique_endpoints = set()
        v3_payloads = 0
        v2_payloads = 0
        
        for i, item in enumerate(items):
            url = item.find('url').text
            unique_endpoints.add(url)
            
            # Look for request body
            req_el = item.find('request')
            if req_el is not None:
                text = req_el.text
                if req_el.get('base64') == 'true':
                    data = base64.b64decode(text)
                else:
                    data = text.encode('utf-8')
                
                # Check for signatures of V3 (JSON) vs V2 (XML inside form)
                if b'"document":' in data or b'"identifier":' in data:
                    v3_payloads += 1
                if b'CD_DOCUMENTO' in data or b'CD_PROPRIEDADE' in data:
                    v2_payloads += 1
                    
        print(f"Unique Endpoints Found: {len(unique_endpoints)}")
        for endpoint in sorted(list(unique_endpoints))[:10]: # Print some endpoints
            print(f" - {endpoint}")
            
        print(f"Detected V3 payloads (potential): {v3_payloads}")
        print(f"Detected V2 payloads (potential): {v2_payloads}")
        
    except Exception as e:
        print(f"Error: {e}")

# Run for the big file and some V2s
analyze_burp_deep(r'j:\replica_lab\burp_analise\save_all_documento_clinico_V3.xml')
analyze_burp_deep(r'j:\replica_lab\burp_analise\save_documento_clinico_V2_1.xml')
