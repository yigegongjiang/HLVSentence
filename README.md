# 文本分句

### Command

```
hlvst --help                                                             

OVERVIEW: Parse Signal Sentence From Text Or File.

USAGE: command <subcommand>

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.

SUBCOMMANDS:
  files (default)         Parse Signal Sentence From Files.
  folder                  Parse Signal Sentence From Folder.
  text                    Parse Signal Sentence From Text.

  See 'command help <subcommand>' for detailed help.
```

```
hlvst files -m -n 10 xx.md xx.txt

hlvst folder -m -n 10 ./

hlvst txt xxx
```

Example：  
file from:https://github.com/yigegongjiang/HLVFileDump/blob/main/README.md

```
hlvst -m -n 5 README.md                                                      

README.md:
0: 文件类型识别
1: 文本文件识别
2: 对于一个文件是否是文本文件，并没有完全行之有效的识别方案。
3: 只能通过尝试去理解内容，这是有一定误差的。
4: 可行的方案有：文件名后缀匹配、magic number 过滤等，虽然会有一定误差，但在比较稳定的环境下，这也是有效的。
5: 对文本内容全量解码，这在文本较小的时候非常行之有效。
6: 若环境中出现图片、压缩文件等，这会有极大的性能损耗。
7: 这里提供一种思路，即对文本内容主动进行多个位置的截取解码，以较小的性能开销来对文本文件进行识别。
8: 通过 magic number 可以非常准确的识别特定的文件类型，这基于 ELF 等类似的二进制文件均具有表现一致的文件头。
```

### Code

```
import HLVSentence

let r = HLVParse.parseZh(text, minZhNum: minZhNum)
```

## Installation

By Swift Package Manager.

```
let package = Package(
    dependencies: [
        .package(url: "https://github.com/yigegongjiang/HLVSentence.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [ .target(dependencies: [...,"HLVSentence"]) ]
)
```
