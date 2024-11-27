# Microsoft Azure

## Création d'un service principal

```shell
az ad sp create-for-rbac --display-name "terraform-service-principal" --role Contributor --scopes /subscriptions//subscriptions/20000000-0000-0000-0000-000000000000
```
