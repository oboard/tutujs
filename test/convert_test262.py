import os
import re
import sys

# Constants
CONFIG_PATH = 'test/test262.conf'
OUTPUT_PREFIX = 'test/test262_'
MAX_TESTS_PER_FILE = 100
OUTPUT_LIST = 'test/test262_files.txt'

class Test262Config:
    def __init__(self):
        self.testdir = ''
        self.harnessdir = ''
        self.excludes = set()
        self.features = {} # feature -> bool (True=include, False=skip)
        self.style = 'new'
        self.run_strict = False
        self.run_nostrict = True # Default mode is usually default-nostrict
        self.skip_async = False
        self.skip_module = False
        self.verbose = False
        self.harness_exclude = set()
        self.tests = [] 

def resolve_path(base, path):
    if not path: return path
    if os.path.isabs(path): return path
    return os.path.normpath(os.path.join(base, path))

def load_list_file(path, target_set, base_dir_of_config):
    if not os.path.exists(path):
        # try relative to base_dir_of_config
        path = resolve_path(base_dir_of_config, path)
        if not os.path.exists(path):
            print(f"Warning: exclude file {path} not found")
            return

    base = os.path.dirname(path)
    try:
        with open(path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#') or line.startswith(';'): continue
                target_set.add(resolve_path(base, line))
    except Exception as e:
        print(f"Error reading list file {path}: {e}")

def parse_config(config_path):
    config = Test262Config()
    if not os.path.exists(config_path):
        print(f"Error: Config file {config_path} not found.")
        return config

    base_dir = os.path.dirname(os.path.abspath(config_path))
    
    with open(config_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    section = None
    
    for line in lines:
        line = line.strip()
        if not line or line.startswith('#') or line.startswith(';'):
            continue
            
        if line.startswith('[') and line.endswith(']'):
            section = line[1:-1].strip()
            continue
            
        if section == 'config':
            if '=' in line:
                parts = line.split('=', 1)
                key = parts[0].strip()
                value = parts[1].strip()
                
                if key == 'testdir':
                    config.testdir = resolve_path(base_dir, value)
                elif key == 'harnessdir':
                    config.harnessdir = resolve_path(base_dir, value)
                elif key == 'excludefile':
                    fpath = resolve_path(base_dir, value)
                    load_list_file(fpath, config.excludes, base_dir)
                elif key == 'features':
                    for f in value.replace(',', ' ').split():
                         config.features[f.strip()] = True
                elif key == 'skip-features':
                     for f in value.replace(',', ' ').split():
                         config.features[f.strip()] = False
                elif key == 'mode':
                    if value in ['default', 'default-nostrict']:
                        config.run_strict = False
                        config.run_nostrict = True
                    elif value == 'default-strict':
                        config.run_strict = True
                        config.run_nostrict = False
                    elif value == 'nostrict':
                        config.run_strict = False
                        config.run_nostrict = True
                    elif value == 'strict':
                        config.run_strict = True
                        config.run_nostrict = False
                    elif value in ['all', 'both']:
                        config.run_strict = True
                        config.run_nostrict = True
                elif key == 'strict':
                    if value == 'yes':
                        config.run_strict = True
                    elif value in ['skip', 'no']:
                        config.run_strict = False
                elif key == 'nostrict':
                    if value == 'yes':
                        config.run_nostrict = True
                    elif value in ['skip', 'no']:
                        config.run_nostrict = False
                elif key == 'async':
                    config.skip_async = (value != 'yes')
                elif key == 'module':
                    config.skip_module = (value != 'yes')
                elif key == 'harnessexclude':
                    for f in value.replace(',', ' ').split():
                        config.harness_exclude.add(f.strip())
                        
        elif section == 'exclude':
            config.excludes.add(resolve_path(base_dir, line))
        elif section == 'features':
             if '=' in line:
                 parts = line.split('=', 1)
                 key = parts[0].strip()
                 value = parts[1].strip()
                 if value == 'yes':
                     config.features[key] = True
                 else:
                     config.features[key] = False
             else:
                 config.features[line] = True
        elif section == 'tests':
            config.tests.append(resolve_path(base_dir, line))
            
    return config

def get_harness_code(filename, config):
    if not config.harnessdir:
        return ""
    path = os.path.join(config.harnessdir, filename)
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()
    return ""

def parse_frontmatter(content):
    match = re.search(r'/\*---(.*?)---\*/', content, re.DOTALL)
    if not match:
        return {}
    
    yaml_content = match.group(1)
    meta = {}
    
    # Simple YAML parser
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
        
    features_match = re.search(r'features:\s*\[(.*?)\]', yaml_content)
    if features_match:
        features = [x.strip() for x in features_match.group(1).split(',')]
        meta['features'] = [f for f in features if f]
    else:
        meta['features'] = []
    
    if 'negative:' in yaml_content:
        meta['negative'] = True
        
    return meta

def should_skip(filepath, meta, config):
    # Check exclude list
    abs_path = os.path.abspath(filepath)
    for excl in config.excludes:
        excl_abs = os.path.abspath(excl)
        if abs_path == excl_abs or abs_path.startswith(excl_abs + os.sep):
            return True, "excluded-by-config"

    # Check features
    for feat in meta.get('features', []):
        if feat in config.features:
            if not config.features[feat]: # Explicitly set to False (skip)
                return True, "feature-disabled"
        # If feature is not in config.features, we skip it to be safe/compliant with config
        elif len(config.features) > 0: # Only if features are defined
             return True, "feature-not-enabled"

    # Check flags
    flags = meta.get('flags', [])
    if config.skip_async and 'async' in flags:
        return True, "async-skipped"
    if config.skip_module and 'module' in flags:
        return True, "module-skipped"
        
    # Check strict mode
    is_only_strict = 'onlyStrict' in flags
    is_no_strict = 'noStrict' in flags
    
    if is_only_strict and not config.run_strict:
        return True, "only-strict-skipped"
    if is_no_strict and not config.run_nostrict:
        return True, "no-strict-skipped"
        
    return False, None

def process_file(filepath, config):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        return False, None, f"read-error: {str(e)}"
        
    meta = parse_frontmatter(content)
    
    skip, reason = should_skip(filepath, meta, config)
    if skip:
        return False, meta, reason
        
    return True, meta, None

def generate_tests():
    config = parse_config(CONFIG_PATH)
    
    # Path correction logic
    if not config.testdir or not os.path.exists(config.testdir):
        fallback = os.path.join('test', 'test262', 'test')
        if os.path.exists(fallback):
            print(f"Configured testdir '{config.testdir}' not found. Using fallback '{fallback}'")
            config.testdir = fallback
        else:
             print(f"Error: testdir '{config.testdir}' not found.")
             return

    if not config.harnessdir or not os.path.exists(config.harnessdir):
        fallback_h = os.path.join('test', 'test262', 'harness')
        if os.path.exists(fallback_h):
             config.harnessdir = fallback_h
             print(f"Configured harnessdir not found. Using fallback '{fallback_h}'")
    
    print(f"Scanning {config.testdir}...")
    
    groups = {}
    all_tests = []
    skipped_stats = {}
    
    for root, dirs, files in os.walk(config.testdir):
        for file in files:
            if not file.endswith('.js') or file.endswith('_FIXTURE.js'):
                continue
            
            filepath = os.path.join(root, file)
            rel_path = os.path.relpath(filepath, config.testdir)
            
            # Determine group
            parts = rel_path.split(os.sep)
            if len(parts) >= 2:
                # e.g. built-ins/Array/foo.js -> built_ins_array
                group_name = f"{parts[0]}_{parts[1]}".lower().replace('-', '_')
            elif len(parts) == 1:
                group_name = parts[0].lower().replace('-', '_')
            else:
                group_name = "misc"
                
            if group_name not in groups:
                groups[group_name] = []
            groups[group_name].append(filepath)

    # Process groups
    for group_name, filepaths in groups.items():
        if not filepaths:
            continue
        print(f"Processing group {group_name}: {len(filepaths)} files")
        valid_tests = []
        for fp in filepaths:
             keep, meta, reason = process_file(fp, config)
             if keep:
                 test_path = os.path.relpath(fp, os.getcwd())
                 valid_tests.append(test_path)
                 all_tests.append(test_path)
             else:
                 skipped_stats[reason] = skipped_stats.get(reason, 0) + 1
                 
        if not valid_tests:
            continue
        print(f"Group {group_name} valid tests: {len(valid_tests)}")

    print("\nSkipped statistics:")
    for reason, count in sorted(skipped_stats.items()):
        print(f"  {reason}: {count}")

    if not all_tests:
        print("No valid tests found.")
        return
    all_tests_sorted = sorted(set(all_tests))
    with open(OUTPUT_LIST, 'w', encoding='utf-8') as out:
        for path in all_tests_sorted:
            out.write(path + '\n')

if __name__ == "__main__":
    generate_tests()
