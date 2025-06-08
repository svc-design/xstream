package main

import "C"
import (
	"encoding/json"
	"io"
	"os"
	"os/exec"
	"path/filepath"
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

//export UpdateVpnNodesConfig
func UpdateVpnNodesConfig(path *C.char, content *C.char) C.int {
	p := C.GoString(path)
	c := C.GoString(content)
	var nodes []map[string]interface{}
	if data, err := os.ReadFile(p); err == nil {
		json.Unmarshal(data, &nodes)
	}
	var newNodes []map[string]interface{}
	if err := json.Unmarshal([]byte(c), &newNodes); err != nil {
		return 1
	}
	nodes = append(nodes, newNodes...)
	out, err := json.MarshalIndent(nodes, "", "  ")
	if err != nil {
		return 1
	}
	if err := os.WriteFile(p, out, 0644); err != nil {
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
	exe, err := os.Executable()
	if err != nil {
		return 1
	}
	base := filepath.Dir(exe)
	src := filepath.Join(base, "xray.exe")
	destDir := filepath.Join(os.Getenv("ProgramData"), "xstream")
	dest := filepath.Join(destDir, "xray.exe")
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return 1
	}
	in, err := os.Open(src)
	if err != nil {
		return 1
	}
	defer in.Close()
	out, err := os.Create(dest)
	if err != nil {
		return 1
	}
	defer out.Close()
	if _, err := io.Copy(out, in); err != nil {
		return 1
	}
	return 0
}

//export ResetXrayAndConfig
func ResetXrayAndConfig(password *C.char) C.int {
	dir := filepath.Join(os.Getenv("ProgramData"), "xstream")
	os.RemoveAll(dir)
	exec.Command("sc", "delete", "xray-node-jp").Run()
	exec.Command("sc", "delete", "xray-node-ca").Run()
	exec.Command("sc", "delete", "xray-node-us").Run()
	return 0
}

func main() {}
