import sys
with open(sys.argv[1], 'rb') as f:
    content = f.read()
if content[:3] == b'\xef\xbb\xbf':
    content = content[3:]
with open(sys.argv[1], 'wb') as f:
    f.write(content)
