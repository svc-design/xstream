package main

import "C"
import (
    "os"
    "os/exec"
    "strings"
)

//export WriteConfigFile
func WriteConfigFile(path *C.char, content *C.char) C.int {
    p := C.GoString(path)
    c := C.GoString(content)
    if err := os.WriteFile(p, []byte(c), 0644); err != nil {
        return 1
    }
    return 0
}

//export StartNodeService
func StartNodeService(name *C.char) C.int {
    cmd := exec.Command("sc", "start", C.GoString(name))
    if err := cmd.Run(); err != nil {
        return 1
    }
    return 0
}

//export StopNodeService
func StopNodeService(name *C.char) C.int {
    cmd := exec.Command("sc", "stop", C.GoString(name))
    if err := cmd.Run(); err != nil {
        return 1
    }
    return 0
}

//export CheckNodeStatus
func CheckNodeStatus(name *C.char) C.int {
    out, err := exec.Command("sc", "query", C.GoString(name)).Output()
    if err != nil {
        return -1
    }
    if strings.Contains(string(out), "RUNNING") {
        return 1
    }
    return 0
}

//export InitXray
func InitXray() C.int {
    return 0
}

//export ResetXrayAndConfig
func ResetXrayAndConfig(password *C.char) C.int {
    return 0
}

func main() {}
