import os
import re

TEST262_DIR = 'test/test262'
TEST_DIR = os.path.join(TEST262_DIR, 'test/built-ins')
HARNESS_DIR = os.path.join(TEST262_DIR, 'harness')
OUTPUT_PREFIX = 'test/test262_built_ins_'

# Map subdirectories to output filenames
GROUPS = {
    'Date': 'date',
    'Array': 'array',
    'String': 'string',
    'Number': 'number',
    'Object': 'object',
    'Math': 'math',
    'Error': 'error',
    'Boolean': 'boolean',
    'Function': 'function',
    'RegExp': 'regexp',
    'Map': 'map',
    'Set': 'set',
    'WeakMap': 'weakmap',
    'WeakSet': 'weakset',
    'Symbol': 'symbol',
    'Promise': 'promise',
    'Proxy': 'proxy',
    'Reflect': 'reflect',
    'JSON': 'json'
}

def parse_frontmatter(content):
    match = re.search(r'/\*---(.*?)---\*/', content, re.DOTALL)
    if not match:
        return {}
    
    yaml_content = match.group(1)
    meta = {}
    
    # Simple YAML parser for "includes: [a.js, b.js]" and "flags: [...]"
    includes_match = re.search(r'includes:\s*\[(.*?)\]', yaml_content)
    if includes_match:
        includes = [x.strip() for x in includes_match.group(1).split(',')]
        meta['includes'] = [i for i in includes if i]
    else:
        meta['includes'] = []

    flags_match = re.search(r'flags:\s*\[(.*?)\]', yaml_content)
    if flags_match:
        flags = [x.strip() for x in flags_match.group(1).split(',')]
        meta['flags'] = [f for f in flags if f]
    else:
        meta['flags'] = []
    
    # Check for negative test
    if 'negative:' in yaml_content:
        meta['negative'] = True
        
    return meta

def get_harness_code(filename):
    path = os.path.join(HARNESS_DIR, filename)
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()
    return ""

def process_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except UnicodeDecodeError:
        return None, None
        
    meta = parse_frontmatter(content)
    
    # Skip negative tests for now
    if meta.get('negative'):
        return None, None

    # Skip if 'module' flag is present
    if 'module' in meta.get('flags', []):
        return None, None
        
    # Default includes
    includes = meta.get('includes', [])
    if 'assert.js' not in includes:
        includes.insert(0, 'assert.js')
    if 'sta.js' not in includes:
        includes.insert(0, 'sta.js')
        
    # Remove duplicates
    seen = set()
    unique_includes = []
    for i in includes:
        if i not in seen:
            unique_includes.append(i)
            seen.add(i)
            
    full_code = ""
    for inc in unique_includes:
        full_code += get_harness_code(inc) + "\n"
        
    full_code += content
    
    # Escape for MoonBit string
    mbt_string = ""
    for line in full_code.splitlines():
        # Escape backslashes inside the string if necessary?
        # MoonBit raw string syntax #| content |# or #| content
        mbt_string += f"    #| {line}\n"
        
    return mbt_string, meta

def generate_tests():
    for group, filename_suffix in GROUPS.items():
        group_dir = os.path.join(TEST_DIR, group)
        if not os.path.exists(group_dir):
            continue
            
        output_file = f"{OUTPUT_PREFIX}{filename_suffix}.mbt"
        print(f"Generating {output_file}...")
        
        with open(output_file, 'w', encoding='utf-8') as out:
            out.write("///| Auto-generated Test262 tests\n\n")
            
            count = 0
            for root, dirs, files in os.walk(group_dir):
                for file in files:
                    if not file.endswith('.js'):
                        continue
                        
                    filepath = os.path.join(root, file)
                    test_name = os.path.relpath(filepath, TEST262_DIR)
                    
                    try:
                        mbt_code, meta = process_file(filepath)
                        if mbt_code is None:
                            continue
                            
                        out.write(f'test "{test_name}" {{\n')
                        out.write(f'  test_from("{filepath}")\n')
                        out.write('}\n\n')
                        count += 1
                        if count >= 100: # Limit per file
                            break
                    except Exception as e:
                        print(f"Error processing {filepath}: {e}")
                        
                if count >= 100:
                    break

if __name__ == "__main__":
    generate_tests()
