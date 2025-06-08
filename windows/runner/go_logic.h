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
int InitXray();
int ResetXrayAndConfig(const char *password);

#ifdef __cplusplus
}
#endif
#endif  // GO_LOGIC_H_
