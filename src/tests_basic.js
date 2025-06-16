console.log('demo.js log ...')

console.log('==> globalThis:')
for (var key in globalThis) {
    console.log("  " + key)
}

console.log('==> std:')
for (var key in std) {
    console.log("  " + key)
}

console.log('==> os:')
for (var key in os) {
    console.log("  " + key)
}

console.log('==> bjson:')
for (var key in bjson) {
    console.log("  " + key)
}

globalThis.std.printf('\n\nhello_world\n');
globalThis.std.printf(globalThis+'\n');


var a = 0xf2;
os.setTimeout(() => { std.printf('timeout: AAB\n') }, 2000)
globalThis.std.printf("a value is %d\n", a);

