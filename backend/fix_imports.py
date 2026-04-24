import os
import re

app_dir = os.path.join(os.path.dirname(__file__), 'app')

for root, dirs, files in os.walk(app_dir):
    for file in files:
        if file.endswith('.py'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()

            new_content = content
            # Fixed the completely broken backend imports
            new_content = re.sub(r'from \.\.\.\.(\w+)', r'from app.\1', new_content)
            new_content = re.sub(r'from \.\.\.(\w+)', r'from app.\1', new_content)
            new_content = re.sub(r'from \.\.deps', r'from app.api.deps', new_content)
            
            # Application/ Core/ Infrastructure level: .. means app folder
            # If we are in application or infrastructure, .. goes to app
            if 'application' in root or 'infrastructure' in root or 'core' in root or 'api' in root:
                new_content = re.sub(r'from \.\.(\w+)', r'from app.\1', new_content)

            if new_content != content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Fixed {path}")
