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

//export WriteConfigFiles
func WriteConfigFiles(xrayPath, xrayContent, plistPath, plistContent, vpnPath, vpnContent *C.char) C.int {
	if WriteConfigFile(xrayPath, xrayContent) != 0 {
		return 1
	}
	if WriteConfigFile(plistPath, plistContent) != 0 {
		return 1
	}
	if UpdateVpnNodesConfig(vpnPath, vpnContent) != 0 {
		return 1
	}
	return 0
}

//export ControlNodeService
func ControlNodeService(action, name *C.char) C.int {
	switch C.GoString(action) {
	case "startNodeService":
		return StartNodeService(name)
	case "stopNodeService":
		return StopNodeService(name)
	case "checkNodeStatus":
		return CheckNodeStatus(name)
	default:
		return -1
	}
}

//export PerformAction
func PerformAction(action, password *C.char) C.int {
	switch C.GoString(action) {
	case "initXray":
		return InitXray()
	case "resetXrayAndConfig":
		return ResetXrayAndConfig(password)
	default:
		return 1
	}
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

//export CreateXrayService
func CreateXrayService(name, configPath *C.char) C.int {
	service := C.GoString(name)
	cfg := C.GoString(configPath)
	exe := filepath.Join(os.Getenv("ProgramData"), "xstream", "xray.exe")
	bin := exe + " run -c " + cfg
	cmd := exec.Command("sc", "create", service, "binPath=", bin, "start=", "auto")
	if err := cmd.Run(); err != nil {
		return 1
	}
	return 0
}

//export DeleteXrayService
func DeleteXrayService(name *C.char) C.int {
	cmd := exec.Command("sc", "delete", C.GoString(name))
	if err := cmd.Run(); err != nil {
		return 1
	}
	return 0
}

//export RestartNodeService
func RestartNodeService(name *C.char) C.int {
	if StopNodeService(name) != 0 {
		return 1
	}
	return StartNodeService(name)
}

func main() {}
