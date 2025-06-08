#ifndef NATIVE_BRIDGE_GO_H
#define NATIVE_BRIDGE_GO_H
#ifdef __cplusplus
extern "C" {
#endif

const char* WriteConfigFiles(const char* xrayPath, const char* xrayContent,
                             const char* servicePath, const char* serviceContent,
                             const char* vpnPath, const char* vpnContent,
                             const char* password);
const char* StartNodeService(const char* serviceName);
const char* StopNodeService(const char* serviceName);
int CheckNodeStatus(const char* serviceName);
const char* InitXray();
const char* ResetXrayAndConfig(const char* password);
void FreeCString(const char* str);

#ifdef __cplusplus
}
#endif
#endif
