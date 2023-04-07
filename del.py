# print((60*80*24*365.25*20/12))

import sha3

def read_pdf_file(file_path):
    with open(file_path, 'rb') as f:
        file_data = f.read()
    return file_data

def compute_keccak256(file_data):
    keccak_hash = sha3.keccak_256()
    keccak_hash.update(file_data)
    return keccak_hash.hexdigest()

# Replace 'path/to/your/pdf_file.pdf' with the path to the PDF file you want to hash
pdf_file_path = '/Users/christophercruttenden/Downloads/shots.pdf'
pdf_data = read_pdf_file(pdf_file_path)
hash_value = compute_keccak256(pdf_data)

print(pdf_data)
print("Keccak256 hash of the PDF file:", hash_value)
