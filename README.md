# lbg-aks-terraform-jenkins

To build the tf bootstrap, ensure you are logged into the correct account with the az command line.

Current naming convention will have a basename and an environment name - EG baseline / (test|dev|production)

To build the initial statefile store and vault, run tf_bootstrap.sh with the basename and environment

tf_bootstrap baseline test

This will check and create (if it doesn't exist) a storage account, vault and a service principle for TF. The credentials for this SP will be stored in the vault.
