package main

import "C"
import (
	"archive/zip"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

//export WriteConfigFile
func WriteConfigFile(path *C.char, content *C.char) C.int {
	p := C.GoString(path)
	c := C.GoString(content)
	if err := os.MkdirAll(filepath.Dir(p), 0755); err != nil {
		return 1
	}
	if err := os.WriteFile(p, []byte(c), 0644); err != nil {
		return 1
	}
	return 0
}

//export UpdateVpnNodesConfig
func UpdateVpnNodesConfig(path *C.char, content *C.char) C.int {
	p := C.GoString(path)
	c := C.GoString(content)
	if err := os.MkdirAll(filepath.Dir(p), 0755); err != nil {
		return 1
	}
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
func WriteConfigFiles(xrayPath, xrayContent, servicePath, serviceContent, vpnPath, vpnContent *C.char) C.int {
	if WriteConfigFile(xrayPath, xrayContent) != 0 {
		return 1
	}
	if WriteConfigFile(servicePath, serviceContent) != 0 {
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
	destDir := filepath.Join(os.Getenv("ProgramData"), "xstream")
	dest := filepath.Join(destDir, "xray.exe")
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return 1
	}

	resp, err := http.Get("https://artifact.onwalk.net/xray-core/v25.3.6/Xray-windows-64.zip")
	if err != nil {
		return 1
	}
	defer resp.Body.Close()

	tmp, err := os.CreateTemp("", "xray-*.zip")
	if err != nil {
		return 1
	}
	if _, err := io.Copy(tmp, resp.Body); err != nil {
		tmp.Close()
		os.Remove(tmp.Name())
		return 1
	}
	tmp.Close()
	defer os.Remove(tmp.Name())

	zr, err := zip.OpenReader(tmp.Name())
	if err != nil {
		return 1
	}
	defer zr.Close()

	var xrayFile *zip.File
	for _, f := range zr.File {
		name := strings.ToLower(filepath.Base(f.Name))
		if name == "xray.exe" {
			xrayFile = f
			break
		}
	}
	if xrayFile == nil {
		return 1
	}
	rc, err := xrayFile.Open()
	if err != nil {
		return 1
	}
	defer rc.Close()

	out, err := os.Create(dest)
	if err != nil {
		return 1
	}
	defer out.Close()
	if _, err := io.Copy(out, rc); err != nil {
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
