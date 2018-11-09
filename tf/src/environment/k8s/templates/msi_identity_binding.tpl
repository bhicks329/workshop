apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentity
metadata:
 name: keyvault-test
spec:
 type: 0
 ResourceID: ${keyvault_test_rid}
 ClientID: ${keyvault_test_cid}

---

apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentityBinding
metadata:
 name: msi-azure-identity-binding
spec:
 AzureIdentity: keyvault-test
 Selector: keyvault-test