
import os
import zipfile

def scan_zip_for_terns(zip_path, terms):
    print(f"--- Scanning ZIP: {zip_path} ---")
    try:
        with zipfile.ZipFile(zip_path, 'r') as z:
            for name in z.namelist():
                if name.endswith('.edt'):
                    with z.open(name) as f:
                        content = f.read().decode('utf-8', errors='ignore')
                        for term in terms:
                            if term.lower() in content.lower():
                                print(f"Found '{term}' in {name}")
    except:
        pass

terms = ['tenant', 'company', 'multi_empresa', 'chave', 'volta']
folder = r'j:\replica_lab\burp_analise'

for f in os.listdir(folder):
    if f.endswith('.zip'):
        scan_zip_for_terns(os.path.join(folder, f), terms)

def scan_xml_for_terms(xml_path, terms):
    print(f"--- Scanning XML: {xml_path} ---")
    try:
        with open(xml_path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                for term in terms:
                    if term.lower() in line.lower():
                        print(f"Found '{term}' in {os.path.basename(xml_path)}")
                        return # Found at least one, move on
    except:
        pass

for f in os.listdir(folder):
    if f.endswith('.xml'):
        scan_xml_for_terms(os.path.join(folder, f), terms)
