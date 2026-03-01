
import os
import xml.etree.ElementTree as ET
import base64
import json

def extract_v3_manifest(path):
    print(f"--- Manifest Extraction: {path} ---")
    try:
        tree = ET.parse(path)
        root = tree.getroot()
        
        results = []
        for item in root.findall('item'):
            url = item.find('url').text
            # Look for /published or /save or /export
            if 'published' in url or 'documents' in url:
                req_el = item.find('request')
                if req_el is not None:
                    # Look for JSON in request body
                    text = req_el.text
                    if req_el.get('base64') == 'true':
                        data = base64.b64decode(text)
                    else:
                        data = text.encode('utf-8')
                    
                    try:
                        # Find start of JSON {
                        start = data.find(b'{')
                        if start != -1:
                            body = data[start:].decode('utf-8', errors='ignore')
                            # Try to find the end of JSON by balancing braces
                            # Simple approach: find name/identifier field
                            if '"identifier":' in body:
                                # Extract identifier and name
                                id_match = json.loads(body[:1000] + ' }') # Hacky check
                                results.append(f"Found Doc: {url}")
                    except:
                        pass
        print(f"Extraction summary: {len(results)} potential hits.")
    except Exception as e:
        print(f"Error: {e}")

extract_v3_manifest(r'j:\replica_lab\burp_analise\save_all_documento_clinico_V3.xml')
