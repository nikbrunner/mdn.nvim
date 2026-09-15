#!/usr/bin/env python3
"""Run a Neovim functional screen scenario with a real terminal UI."""

import errno
import fcntl
import os
import pty
import select
import signal
import struct
import sys
import termios
import time


def main() -> int:
    if len(sys.argv) != 4:
        print("usage: run_render_screen.py NVIM SCRIPT SCENARIO", file=sys.stderr)
        return 2

    nvim, script, scenario = sys.argv[1:]
    pid, fd = pty.fork()
    if pid == 0:
        os.environ["TERM"] = "xterm-256color"
        os.environ["MDN_SCREEN_SCRIPT"] = script
        os.environ["MDN_SCREEN_SCENARIO"] = scenario
        command = (
            "local ok, err = xpcall(function() dofile(vim.env.MDN_SCREEN_SCRIPT) end, debug.traceback); "
            "if ok then vim.cmd('qa!') else io.stderr:write(err .. '\\n'); vim.cmd('cquit') end"
        )
        os.execv(nvim, [nvim, "-u", "NONE", "-i", "NONE", "--noplugin", "-c", "lua " + command])

    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 100, 0, 0))
    output = bytearray()
    deadline = time.monotonic() + 20
    status = None

    while status is None:
        waited_pid, waited_status = os.waitpid(pid, os.WNOHANG)
        if waited_pid == pid:
            status = waited_status
            break
        if time.monotonic() >= deadline:
            os.kill(pid, signal.SIGKILL)
            _, status = os.waitpid(pid, 0)
            print("screen scenario timed out", file=sys.stderr)
            break
        readable, _, _ = select.select([fd], [], [], 0.1)
        if fd in readable:
            try:
                chunk = os.read(fd, 65536)
                if chunk:
                    output.extend(chunk)
            except OSError as error:
                if error.errno != errno.EIO:
                    raise

    try:
        while True:
            chunk = os.read(fd, 65536)
            if not chunk:
                break
            output.extend(chunk)
    except OSError as error:
        if error.errno != errno.EIO:
            raise
    finally:
        os.close(fd)

    if os.WIFEXITED(status) and os.WEXITSTATUS(status) == 0:
        return 0

    sys.stderr.buffer.write(output)
    if os.WIFEXITED(status):
        return os.WEXITSTATUS(status)
    return 128 + os.WTERMSIG(status)


if __name__ == "__main__":
    raise SystemExit(main())
