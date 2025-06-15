//go:build windows

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

func cStringOrError(err error) *C.char {
	if err != nil {
		return C.CString("error:" + err.Error())
	}
	return C.CString("success")
}

//export WriteConfigFiles
func WriteConfigFiles(xrayPath, xrayContent, servicePath, serviceContent, vpnPath, vpnContent, password *C.char) *C.char {
	if res := writeConfigFile(xrayPath, xrayContent); res != nil {
		return res
	}
	if res := writeConfigFile(servicePath, serviceContent); res != nil {
		return res
	}
	return updateVpnNodesConfig(vpnPath, vpnContent)
}

func writeConfigFile(pathC, contentC *C.char) *C.char {
	p := C.GoString(pathC)
	c := C.GoString(contentC)
	if err := os.MkdirAll(filepath.Dir(p), 0755); err != nil {
		return C.CString("error:" + err.Error())
	}
	if err := os.WriteFile(p, []byte(c), 0644); err != nil {
		return C.CString("error:" + err.Error())
	}
	return nil
}

func updateVpnNodesConfig(pathC, contentC *C.char) *C.char {
	p := C.GoString(pathC)
	c := C.GoString(contentC)
	if err := os.MkdirAll(filepath.Dir(p), 0755); err != nil {
		return C.CString("error:" + err.Error())
	}
	var nodes []map[string]interface{}
	if data, err := os.ReadFile(p); err == nil {
		json.Unmarshal(data, &nodes)
	}
	var newNodes []map[string]interface{}
	if err := json.Unmarshal([]byte(c), &newNodes); err != nil {
		return C.CString("error:" + err.Error())
	}
	nodes = append(nodes, newNodes...)
	out, err := json.MarshalIndent(nodes, "", "  ")
	if err != nil {
		return C.CString("error:" + err.Error())
	}
	if err := os.WriteFile(p, out, 0644); err != nil {
		return C.CString("error:" + err.Error())
	}
	return C.CString("success")
}

//export StartNodeService
func StartNodeService(name *C.char) *C.char {
	cmd := exec.Command("sc", "start", C.GoString(name))
	err := cmd.Run()
	return cStringOrError(err)
}

//export StopNodeService
func StopNodeService(name *C.char) *C.char {
	cmd := exec.Command("sc", "stop", C.GoString(name))
	err := cmd.Run()
	return cStringOrError(err)
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

//export PerformAction
func PerformAction(action, password *C.char) *C.char {
	switch C.GoString(action) {
	case "initXray":
		return InitXray()
	case "resetXrayAndConfig":
		return ResetXrayAndConfig(password)
	default:
		return C.CString("error:unknown action")
	}
}

//export InitXray
func InitXray() *C.char {
	destDir := filepath.Join(os.Getenv("ProgramData"), "xstream")
	dest := filepath.Join(destDir, "xray.exe")
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return C.CString("error:" + err.Error())
	}
	resp, err := http.Get("https://artifact.onwalk.net/xray-core/v25.3.6/Xray-windows-64.zip")
	if err != nil {
		return C.CString("error:" + err.Error())
	}
	defer resp.Body.Close()
	tmp, err := os.CreateTemp("", "xray-*.zip")
	if err != nil {
		return C.CString("error:" + err.Error())
	}
	if _, err := io.Copy(tmp, resp.Body); err != nil {
		tmp.Close()
		os.Remove(tmp.Name())
		return C.CString("error:" + err.Error())
	}
	tmp.Close()
	defer os.Remove(tmp.Name())
	zr, err := zip.OpenReader(tmp.Name())
	if err != nil {
		return C.CString("error:" + err.Error())
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
		return C.CString("error:xray.exe not found")
	}
	rc, err := xrayFile.Open()
	if err != nil {
		return C.CString("error:" + err.Error())
	}
	defer rc.Close()
	out, err := os.Create(dest)
	if err != nil {
		return C.CString("error:" + err.Error())
	}
	defer out.Close()
	if _, err := io.Copy(out, rc); err != nil {
		return C.CString("error:" + err.Error())
	}
	return C.CString("success")
}

//export ResetXrayAndConfig
func ResetXrayAndConfig(password *C.char) *C.char {
	dir := filepath.Join(os.Getenv("ProgramData"), "xstream")
	os.RemoveAll(dir)
	exec.Command("sc", "delete", "xray-node-jp").Run()
	exec.Command("sc", "delete", "xray-node-ca").Run()
	exec.Command("sc", "delete", "xray-node-us").Run()
	return C.CString("success")
}
