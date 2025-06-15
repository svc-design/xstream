#ifndef GO_LOGIC_H_
#define GO_LOGIC_H_
#ifdef __cplusplus
extern "C" {
#endif

char *WriteConfigFile(const char *path, const char *content);
char *UpdateVpnNodesConfig(const char *path, const char *content);
char *StartNodeService(const char *name);
char *StopNodeService(const char *name);
int CheckNodeStatus(const char *name);
char *WriteConfigFiles(const char *xray_path, const char *xray_content,
                       const char *service_path, const char *service_content,
                       const char *vpn_path, const char *vpn_content,
                       const char *password);
char *InitXray();
char *ResetXrayAndConfig(const char *password);
void FreeCString(char *str);

#ifdef __cplusplus
}
#endif
#endif  // GO_LOGIC_H_
