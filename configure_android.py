from pathlib import Path
import re

manifest = Path('android/app/src/main/AndroidManifest.xml')
if not manifest.exists():
    raise SystemExit('AndroidManifest.xml not found. Run flutter create first.')

text = manifest.read_text(encoding='utf-8')
permissions = [
    '    <uses-permission android:name="android.permission.INTERNET" />',
    '    <uses-permission android:name="android.permission.CAMERA" />',
]
for permission in permissions:
    match = re.search(r'android:name="([^"]+)"', permission)
    if match is None:
        continue
    permission_name = match.group(1)
    if permission_name not in text:
        text = text.replace('<application', permission + '\n    <application', 1)

text = re.sub(r'android:label="[^"]*"', 'android:label="OMNI"', text, count=1)
manifest.write_text(text, encoding='utf-8')
print('Android label and permissions configured.')
