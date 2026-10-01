"""Keep the existing ARM decoder and add the official matching Intel plugin."""
import pathlib, subprocess, sys, shutil, re
root, out = map(pathlib.Path, sys.argv[1:])
plugins = list(root.rglob('libgstapplemedia.dylib'))
if not plugins: raise SystemExit('Official GStreamer applemedia plugin not found')
plugin = plugins[0]
(out / 'lib/gstreamer-1.0').mkdir(parents=True, exist_ok=True)
subprocess.run(['lipo', str(plugin), '-thin', 'x86_64', '-output', str(out / 'applemedia-x86_64.dylib')], check=True)
merged = out / 'lib/gstreamer-1.0/libgstapplemedia.dylib'
subprocess.run(['lipo', '-create', 'assets/gstreamer/macos-arm64/lib/gstreamer-1.0/libgstapplemedia.dylib', str(out / 'applemedia-x86_64.dylib'), '-output', str(merged)], check=True)
queue, seen = [plugin], set()
while queue:
    binary = queue.pop()
    for name in re.findall(r'@rpath/([^ \n]+)', subprocess.check_output(['otool','-L',str(binary)], text=True)):
        if name in seen or name == 'libgstapplemedia.dylib': continue
        seen.add(name)
        if (pathlib.Path('assets/gstreamer/macos-arm64/lib') / name).exists(): continue
        matches = list(root.rglob(name))
        if not matches: raise SystemExit('Missing runtime dependency: ' + name)
        dest = out / 'lib' / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(matches[0], dest)
        queue.append(matches[0])
for binary in [merged, *[p for p in (out/'lib').glob('*.dylib')]]:
    rpath = '@loader_path/..' if binary == merged else '@loader_path'
    load_commands = subprocess.check_output(['otool', '-l', str(binary)], text=True)
    if f'path {rpath} (offset' not in load_commands:
        subprocess.run(['install_name_tool','-add_rpath',rpath,str(binary)], check=True)
    subprocess.run(['codesign','--force','--sign','-',str(binary)], check=True)
