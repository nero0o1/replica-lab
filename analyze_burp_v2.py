
import os
import xml.etree.ElementTree as ET
import base64
import urllib.parse

def decode_burp_xml(path, limit=50):
    print(f"--- Decoding Burp Export: {path} ---")
    try:
        tree = ET.parse(path)
        root = tree.getroot()
        
        items = root.findall('item')
        print(f"Total items: {len(items)}")
        
        for i, item in enumerate(items[:limit]):
            url_el = item.find('url')
            url = url_el.text if url_el is not None else "Unknown"
            request_el = item.find('request')
            request_text = request_el.text
            
            if request_el.get('base64') == 'true':
                request_bytes = base64.b64decode(request_text)
            else:
                request_bytes = request_text.encode('utf-8')
            
            parts = request_bytes.split(b'\r\n\r\n', 1)
            if len(parts) > 1:
                body = parts[1]
                print(f"[{i}] URL: {url}")
                try:
                    decoded_body = body.decode('utf-8', errors='ignore')
                    # Search for specific markers
                    if 'json' in decoded_body.lower() or '{' in decoded_body:
                        print(f"Body snippet: {decoded_body[:150]}...")
                    elif '<xml' in decoded_body.lower() or '<' in decoded_body:
                        print(f"Body snippet (XML): {decoded_body[:150]}...")
                except:
                    pass
            print("-" * 10)
            
    except Exception as e:
        print(f"Error parsing XML: {e}")

decode_burp_xml(r'j:\replica_lab\burp_analise\save_documento_clinico_V2.xml', limit=20)
