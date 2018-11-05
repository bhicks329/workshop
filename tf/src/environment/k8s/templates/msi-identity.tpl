apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentity
metadata:
 name: ${binding_name}
spec:
 type: 0
 ResourceID: ${msi_id}
 ClientID: ${client_id}
---
apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentityBinding
metadata:
 name: msi-azure-identity-binding
spec:
 AzureIdentity: ${binding_name}
 Selector: ${selector_label}