#ifndef GO_LOGIC_H_
#define GO_LOGIC_H_
#ifdef __cplusplus
extern "C" {
#endif

int WriteConfigFile(const char *path, const char *content);
int UpdateVpnNodesConfig(const char *path, const char *content);
int StartNodeService(const char *name);
int StopNodeService(const char *name);
int CheckNodeStatus(const char *name);
int WriteConfigFiles(const char *xray_path, const char *xray_content,
                     const char *service_path, const char *service_content,
                     const char *vpn_path, const char *vpn_content);
int ControlNodeService(const char *action, const char *name);
int PerformAction(const char *action, const char *password);
int InitXray();
int ResetXrayAndConfig(const char *password);

#ifdef __cplusplus
}
#endif
#endif  // GO_LOGIC_H_
