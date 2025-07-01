# zkeke
a gui framework for zig.
draw all ui elements by software.



how  to use:
```bash
git clone https://github.com/BBDXF/zkeke.git --recursive
git submodule update --init
zig build
```

# demos
- basic module and usage
```go
const std = @import("std");
const builtin = @import("builtin");
const comm = @import("zkeke").comm;
const yoga = @import("zkeke").yoga;
const qjs = @import("zkeke").quickjs;
const cairo = @import("zkeke").cairo;
const window = @import("zkeke").window;

pub fn main() !void {
    const app = qjs.Quickjs.init();
    defer app.deinit();
    _ = app.eval_js_code("console.log('hello world');", false);
    _ = app.loop();
}
```

# quickjs
- qjs : interactive cmd line tool
- qjsc : compile js to c code or binary js module

```bash
λ qjs --help                                                                             
QuickJS-ng version 0.10.1                                                                
usage: qjs [options] [file [args]]                                                       
-h  --help         list options                                                          
-e  --eval EXPR    evaluate EXPR                                                         
-i  --interactive  go to interactive mode                                                
-C  --script       load as JS classic script (default=autodetect)                        
-m  --module       load as ES module (default=autodetect)                                
-I  --include file include an additional file                                            
    --std          make 'std', 'os' and 'bjson' available to script                      
-T  --trace        trace memory allocation                                               
-d  --dump         dump the memory usage stats                                           
-D  --dump-flags   flags for dumping debug data (see DUMP_* defines)                     
-c  --compile FILE compile the given JS file as a standalone executable                  
-o  --out FILE     output file for standalone executables                                
    --exe          select the executable to use as the base, defaults to the current one 
    --memory-limit n       limit the memory usage to 'n' Kbytes                          
    --stack-size n         limit the stack size to 'n' Kbytes                            
-q  --quit         just instantiate the interpreter and quit                             


λ qjsc --help                                                                            
QuickJS-ng Compiler version 0.10.1                                                       
usage: qjsc [options] [files]                                                            
                                                                                         
options are:                                                                             
-b          output raw bytecode instead of C code                                        
-e          output main() and bytecode in a C file                                       
-o output   set the output filename                                                      
-n script_name    set the script name (as used in stack traces)                          
-N cname    set the C name of the generated data                                         
-C          compile as JS classic script (default=autodetect)                            
-m          compile as ES module (default=autodetect)                                    
-D module_name         compile a dynamically loaded module or worker                     
-M module_name[,cname] add initialization code for an external C module                  
-p prefix   set the prefix of the generated C names                                      
-P          do not add default system modules                                            
-s          strip the source code, specify twice to also strip debug info                
-S n        set the maximum stack size to 'n' bytes (default=1048576)                    
```

# Note
- add demo test basic functions
- wrapper yoga cpp to zig struct and interface
- wrapper quickjs-ng to zig struct and interface
- wrapper cairo to zig struct and interface 
- wrapper windows management



