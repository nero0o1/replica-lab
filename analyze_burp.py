
import os
import xml.etree.ElementTree as ET
import base64
import urllib.parse

def decode_burp_xml(path):
    print(f"--- Decoding Burp Export: {path} ---")
    try:
        tree = ET.parse(path)
        root = tree.getroot()
        
        for i, item in enumerate(root.findall('item')):
            url = item.find('url').text
            request_el = item.find('request')
            request_text = request_el.text
            
            if request_el.get('base64') == 'true':
                request_bytes = base64.b64decode(request_text)
            else:
                request_bytes = request_text.encode('utf-8')
            
            # Extract body from HTTP request
            # Usually split by double newline
            parts = request_bytes.split(b'\r\n\r\n', 1)
            if len(parts) > 1:
                body = parts[1]
                # If it's multipart or form-urlencoded, we might need more decoding
                print(f"[{i}] URL: {url}")
                try:
                    # Try to decode body as utf-8 or similar
                    decoded_body = body.decode('utf-8', errors='ignore')
                    # If it's URL encoded
                    if 'application/x-www-form-urlencoded' in request_bytes.decode('utf-8', errors='ignore'):
                        decoded_body = urllib.parse.unquote_plus(decoded_body)
                    
                    print(f"Body snippet (200 chars): {decoded_body[:200]}...")
                    
                    # Look for editor versions
                    if '"document":' in decoded_body or 'editor.version' in decoded_body:
                        print(">>> Potential V3 Editor Payload found")
                    elif 'CD_DOCUMENTO' in decoded_body or 'xml' in decoded_body:
                        print(">>> Potential V2 Editor Payload found")
                        
                except Exception as e:
                    print(f"Error decoding body: {e}")
            print("-" * 20)
            
    except Exception as e:
        print(f"Error parsing XML: {e}")

decode_burp_xml(r'j:\replica_lab\burp_analise\save_documento_clinico_V2.xml')
decode_burp_xml(r'j:\replica_lab\burp_analise\save_documento_clinico_V3.xml')
