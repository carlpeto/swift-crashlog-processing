# Swift Plain Text Crash Log Format

## Overview

This document describes the plain text crash log format produced by the Swift
runtime crash logger (`swift-backtrace`) and consumed/produced by
`swift-symbolicate`. The format is a line-oriented, human-readable rendering of
a `CrashLog` model containing the program's death description, per-thread
register dumps and backtraces, the loaded image map, and timing information.

It is the same format whether the log is unsymbolicated (raw addresses only) or
symbolicated (each frame line has the resolved symbol, offset, image, and
optional source location appended). `swift-symbolicate` parses the
unsymbolicated form, resolves addresses against debug info, and re-serialises
the same structure.

The authoritative parser is `Sources/SwiftSymbolicate/PlainCrashLogReader.swift`;
the authoritative writer is `Sources/SwiftSymbolicate/PlainCrashLogWriter.swift`.
Where this document and the source disagree, the source wins.

Note: this document is written largely for swift-symbolicate. But should be
useable in other circumstances. However, it is NOT intended to be any kind of
formal spec. In particular, as stated above, the plain text crash log format
is not intended to be set in stone and might evolve later. At that time the
authors make no promise to keep this document up to date (as mentioned above).

If you are looking for a reliable interop format for crash dumps, it is
strongly recommended to use the JSON format that is built-in to swift-backtrace
and the Runtime module underneath it. This is the correct way to create
machine readable crash logs that are stable and future proof.

SwiftSymbolicate reads the plain text crash logs as a convenience, given they
are likely to be present in ad-hoc human readable log files.

## Embedding and Boundaries

A plain text crash log can appear inline within an arbitrary stream (e.g. mixed
with stdout/stderr, log lines, or noise). Detection is byte-stream based:

- **Start sentinel:** the literal substring `␣Program crashed:␣` (a leading
  space, the words `Program crashed:`, and a trailing space). Note that the
  emitted header is `*** Program crashed: …`, so the start sentinel matches
  the space between `***` and `Program`.
- **End sentinel:** the literal substring `Backtrace took ` followed by up to
  ~100 characters and a terminating `s`.

Anything before the start sentinel or after the end sentinel passes through
unchanged. Multiple crash logs in one stream are supported: each is detected,
parsed, and rewritten independently.

Newlines are normalised on read: `\r\n` is converted to `\n` before parsing,
so the format is portable between Windows-emitted and Unix-emitted logs.
(This conversion will only happen within the part of the stream that
has the crash log. Non crash log should have line endings unaffected.)

## High-Level Grammar

A crash log consists of five sections in this order:

```
<description-header>
<blank line>
<platform-line>
<blank line>
<thread-block>+               # one block per thread
[<crashed-thread-registers>]  # only if registers were dumped only for the crashed thread
<images-block>
<backtrace-time-line>
```

A thread-block has the following internal layout:

```
Thread <n>[ <name>][ crashed]:
<blank line>
[<register-dump>
<blank line>]
<frame-line>+
<blank line>
```

The writer always emits a blank line *before* each `Thread` header (rendered as
`<lineSeparator>Thread …:`) and *after* each backtrace, so consecutive thread
blocks are separated by at least one blank line. The reader is tolerant of
extra blank lines between sections.

## 1. Description Header

```
*** Program crashed: <description> ***
```

Examples:

```
*** Program crashed: Bad pointer dereference at 0x000000000deadbee ***
*** Program crashed: Access violation at 0x0000000000000006 ***
```

- The reader regex is `Program crashed: (.+) [*]*` — i.e. the captured
  description is everything between `Program crashed: ` and the trailing run
  of asterisks (with one separating space).
- If the description has the shape `<reason> at 0x<hex>`, the trailing hex is
  also extracted as the `faultAddress`. Otherwise `faultAddress` is empty.
- Lines such as `*** Signal 11: Backtracing from … done ***` or
  `*** Exception c0000005: Backtracing from … done ***` may appear *before*
  this header in the wider stream; they are not part of the crash log proper
  and are not parsed (they will fall outside the start sentinel).

## 2. Platform Line

```
Platform: <architecture> <os-and-version-info>
```

Examples:

```
Platform: arm64 macOS 26.1 (25B64)
Platform: x86_64 Windows 11.0 build 26200
```

- The whole text after `Platform: ` is preserved as `platform`.
- The first whitespace-delimited token is also extracted separately as
  `architecture` (e.g. `arm64`, `x86_64`, `i386`, `arm`). Architecture drives
  the register order and compact-register layout used by the writer.

## 3. Thread Blocks

Each thread is introduced by a header line:

```
Thread <index>[ <name>][ crashed]:
```

- `<index>` is a non-negative integer. Threads are emitted in numeric index
  order; the reader sorts them by index too.
- `<name>` is optional human-readable text (free-form, may contain spaces).
  When present it is preceded by a single space.
- The literal suffix ` crashed` (with leading space) marks the thread that
  hit the fault. Exactly one thread typically carries this suffix.

After the header line, a blank line separates the header from the thread's
contents.

### 3a. Per-Thread Register Dump (optional)

Some logs include a register dump *inside* every thread block, immediately
following the blank line after the header. Other logs only include registers
once at the end of the file (see §4). Both shapes are valid.

A register dump is a sequence of lines, each shaped like:

```
<name> 0x<hex-value>  <decimal-or-memory-bytes>
```

The name is right-padded to a width of 3 (so `x0` becomes `␣x0`, `fp` becomes
`␣fp`, `x10` stays `x10`). After the hex value there are **two spaces**, then
either:

- a single decimal integer (the value re-rendered in base 10), e.g.
  `␣x0 0x0000000000000001  1`, or
- a captured memory dump: 16 space-separated hex bytes, then two spaces, then
  a 16-character printable rendering (non-printable bytes shown as `·`),
  e.g.
  ```
   x3 0x00000001056240a0  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ················
  ```

The reader recognises register lines using the regex
`[ ]*[^ ]+ 0x[0-9a-f]+  [0-9a-fA-Z]+` (note the **two spaces** before the
trailing token; this is what distinguishes a register line from an
unsymbolicated frame line).

#### Architecture-specific layout

The writer follows the architecture's canonical register dump order:

- `arm64` and other (default): `ARM64Context.registerDumpOrder`
- `arm`: `ARMContext.registerDumpOrder`
- `x86_64`: `X86_64Context.registerDumpOrder`, with a **blank line before
  `rflags`**, and a blank line before a compact final line
  `cs 0x<6-hex>  fs 0x<6-hex>  gs 0x<6-hex>` (each value is the last 6 hex
  characters of the underlying register).
- `i386`: `I386Context.registerDumpOrder`, with a blank line before `eflags`,
  and a blank line before a compact final line covering
  `es cs ss ds fs gs`.

The reader handles the compact line by also matching `([^ ]+) (0x[0-9a-f]+)`
multiple times per remaining line (so all of `cs`, `fs`, `gs` are recovered
from the single compact line).

### 3b. Backtrace Frames

The frames follow the register dump (or follow the header's blank line if no
per-thread registers are present). Each frame is one line:

```
  <index>[ <type-tags>] <address>[ <symbolication>]
```

Where:

- `<index>` is the frame's position in the call stack (0 = innermost).
- `<type-tags>` is zero or more tags in the form `[xxx]` separated by spaces.
  Recognised tags include:
  - `[ra]` — return address (the address points one past the call site;
    parsed as `kind = returnAddress`).
  - `[async]` — async resume point (`kind = asyncResumePoint`).
  - `[thunk]` — compiler-generated thunk (informational).
  - `[system]` — system/runtime frame (informational, e.g. `start` in dyld).
  - The reader's frame regex `[ ]*([0-9]+) (\[[a-z]+\])? +(.*)` captures only
    a single tag in the typed group; subsequent tags are folded into the
    address-and-symbolication remainder. The writer's `BacktraceFormatter`
    is responsible for the canonical multi-tag rendering on output.
- `<address>` is `0x` + lower-case hex, padded to the platform's pointer
  width (16 hex digits for 64-bit, 8 for 32-bit).
- `<symbolication>` (only present in symbolicated logs) follows the address
  and contains a space-separated symbol description, typically:
  ```
  <demangled-symbol> + <byte-offset> in <image-name>[ at <source-path>[:<line>[:<col>]]]
  ```
  Generated/synthetic source paths use placeholders such as
  `/<compiler-generated>`.

A truncated backtrace is indicated by a final line of the form:

```
<index>      ...
```

The literal `...` (ASCII three dots) replaces what would be the address. The
reader maps this to `kind = truncated` with `address = nil`.

#### Examples

Unsymbolicated:

```
0      0x0000000104ea8a1c
1 [ra] 0x000000019d1b9d54
2      ...
```

Symbolicated:

```
  0              0x000000018db5f308 __semwait_signal + 8 in libsystem_kernel.dylib
  1 [ra]         0x000000018da44e24 sleep + 52 in libsystem_c.dylib
  2 [ra]         0x0000000100b69208 static MultithreadedCrash.main() + 636 in crashMeMultithreaded at /Users/.../crashMeMultithreaded.swift:88:7
  3 [ra] [system] 0x0000000100b69450 static MultithreadedCrash.$main() + 12 in crashMeMultithreaded at /<compiler-generated>
```

The writer aligns the fields using `BacktraceFormatter`, sized to the
terminal width (`auto`) or a fixed column count.

## 4. Crashed-Thread Registers (alternative placement)

If — and only if — *no* thread carries an embedded register dump (i.e. the
crash log was produced with `registers=crashed`), the writer emits a single
register block at the end of the threads, before the images, prefixed with:

```
Registers:
<blank line>
<register lines, same format as §3a>
<blank line>
```

The reader treats this block as belonging to the crashed thread: at the end
of parsing, the captured register text is attached to whichever thread had
the ` crashed` suffix.

The reader uses the regex `Registers:` to detect the start of this block and
expects a blank line before the actual register lines.

## 5. Images Section

```
Images[ (<N> omitted)]:
<blank line>
<image-line>+
```

- Header regex: `Images (\([0-9]+ omitted\))?:` — the `(N omitted)` clause is
  optional. When present, `omittedImages` is set to `N`; this captures the
  fact that the runtime didn't include every loaded image (typically because
  no frame in any backtrace referenced it).
- Each image line has the form:

  ```
  0x<base>–0x<end-of-text> <build-id> <image-name> <image-path>
  ```

  matched against
  `(0x[0-9a-f]+)[-−‐–](0x[0-9a-f]+) ([0-9a-f]+(?::[0-9a-f]+)?|<no build ID>) +([^ ]+) +([^ ]+)`.

  Notes:
  - The dash between addresses may be any of the four characters
    `-` (U+002D hyphen-minus), `−` (U+2212 minus sign), `‐` (U+2010 hyphen),
    or `–` (U+2013 en-dash). The writer emits U+2013 en-dash.
  - `<build-id>` is a contiguous lower-case hex string. It may optionally
    contain a single `:`-delimited age field (`<hex>:<hex>`), which is the
    Windows PE/PDB convention used to distinguish builds by signature+age.
    A binary with no recoverable build ID is represented as the literal text
    `<no build ID>`.
  - `<image-name>` is the basename of the binary (e.g. `crashMe`,
    `dyld`, `KERNEL32.DLL`). It may not contain spaces.
  - `<image-path>` is the absolute, possibly platform-specific full path
    (POSIX paths on macOS/Linux, Windows paths on Windows). Spaces in paths
    are not currently supported by the reader regex.
  - Columns are space-padded so that names and paths line up vertically;
    the writer uses `BacktraceFormatter.format(images:)` to compute the
    column widths.

#### Examples

```
0x0000000104ea8000–0x0000000104eac000 6fdbb104c032301189bae26d5506e11a crashMe /Users/carlpeto/Desktop/crashMe
0x000000019d1b1000–0x000000019d24ff64 175354de24cb330199ef3ce9f1952bfd dyld    /usr/lib/dyld
0x00007ff963fb0000–0x00007ff964037000 998bcab6c71d2c69fb6097d608fb6ace01000000 KERNEL32.DLL C:\windows\System32\KERNEL32.DLL
```

## 6. Backtrace Time

The final line of the crash log:

```
Backtrace took <seconds>s
```

- `<seconds>` is a base-10 floating-point value (parsed by `Double(_:)`).
- Detection regex: `Backtrace took ([0-9.]+)s`.
- This line acts as the end sentinel of the entire crash log; the byte-level
  scanner stops capturing after it.

## State Machine Summary (Reader)

For implementers: the parser is a line-oriented state machine over
`split(separator: "\n")`. Its states (from `PlainCrashLogReader.State`):

| State                          | Transition trigger                                    | Goes to                          |
| ------------------------------ | ----------------------------------------------------- | -------------------------------- |
| `started`                      | line matches `Program crashed: …`                     | `foundDescription`               |
| `foundDescription`             | line matches `Platform: …`                            | `searchingForThreadOrRegisters`  |
| `searchingForThreadOrRegisters`| `Thread N[ name][ crashed]:`                          | `startingThread`                 |
|                                | `Registers:`                                          | `startingRegisters`              |
|                                | a register-shaped line                                | (accumulate, stay in state)      |
|                                | `Images …:`                                           | `startingImages`                 |
|                                | `Backtrace took …s`                                   | `complete`                       |
| `startingThread`               | blank line                                            | `inThread`                       |
| `inThread`                     | blank line                                            | `searchingForThreadOrRegisters`  |
|                                | register-shaped line                                  | `inThreadRegisters`              |
|                                | other                                                 | append to thread backtrace       |
| `inThreadRegisters`            | blank line                                            | `inThread`                       |
|                                | other                                                 | append to thread registers       |
| `startingRegisters`            | blank line                                            | `inRegisters`                    |
| `inRegisters`                  | blank line                                            | `searchingForThreadOrRegisters`  |
|                                | other                                                 | append to crashed-thread regs    |
| `startingImages`               | blank line                                            | `inImages`                       |
| `inImages`                     | `Backtrace took …s`                                   | `complete`                       |
|                                | non-empty line                                        | append as image                  |
| `complete`                     | (terminal)                                            | —                                |

A successful parse requires reaching `complete`; otherwise the parser
returns `nil` and `swift-symbolicate` passes the original text through
unchanged.

## Edge Cases and Tolerances

- **Mixed line endings.** `\r\n` is converted to `\n` before line splitting,
  both for the whole log and for the captured raw register/backtrace text
  inside threads.
- **Stray non-crash output before the header.** Anything between the previous
  byte stream and the start sentinel (` Program crashed: `) is passed
  through; it does not break detection.
- **Blank lines.** The parser is forgiving of additional blank lines between
  sections. The writer always emits exactly one blank separator.
- **No thread is marked crashed.** Permitted; the trailing `Registers:` block,
  if present, will not be reattached to any thread.
- **No images section / `Images (0 omitted):`.** Permitted. `omittedImages`
  becomes `0` or stays unset; `images` may be empty.
- **Truncated backtrace marker (`...`).** Parsed as a single frame with
  `kind = truncated` and no address. The writer round-trips it.
- **Frame symbolication is discarded by the reader.** The reader splits the
  remainder of a frame line on whitespace and keeps only the first token
  (the address). Re-symbolication is performed from scratch by the writer
  using the resolved image map. This means feeding an already-symbolicated
  log into `swift-symbolicate` is safe — the existing symbol text will be
  replaced rather than concatenated.
- **Captured memory.** When a register's value points to memory the runtime
  was able to read, the 16 hex bytes following the `<register> <hex>  ` are
  detected and stored separately as `capturedMemory[<address>] = <hex>`.
  The writer uses this to re-render the bytes plus printable-ASCII column on
  output, even after symbolication.

## Cross-Reference: JSON Form

The same `CrashLog` model is also serialisable as JSON (see
`Sources/SwiftSymbolicate/JSONCrashLogWriter.swift` and the
`JsonLogStreamReaderWriter`). Field correspondence:

| Plain text                              | JSON field                       |
| --------------------------------------- | -------------------------------- |
| `*** Program crashed: <X> ***`          | `description` (and `faultAddress` if `… at 0x…`) |
| `Platform: <X>`                         | `platform` (full string), `architecture` (first token) |
| `Thread N[ name][ crashed]:`            | `threads[i].name`, `threads[i].crashed` |
| Per-thread register lines               | `threads[i].registers` (object) |
| Frame lines                             | `threads[i].frames[]` with `kind` and `address` |
| Trailing `Registers:` block             | `threads[i].registers` of the crashed thread |
| `Images (N omitted):`                   | `omittedImages` |
| Image lines                             | `images[]` (`name`, `buildId`, `path`, `baseAddress`, `endOfText`) |
| Captured memory beyond the register row | `capturedMemory` (object) |
| `Backtrace took Xs`                     | `backtraceTime` |

The plain text and JSON forms are lossless with respect to each other for
the fields enumerated above.
