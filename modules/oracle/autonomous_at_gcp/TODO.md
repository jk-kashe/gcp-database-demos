# TODO

## Known Issues

### `odb_network` Force Replacement
- **Symptom:** When redeploying or modifying this module, Terraform sometimes plans to replace the `google_oracle_database_autonomous_database` resource because `odb_network` and `odb_subnet` attributes change to `null`.
- **Context:** This typically happens even when the `network` input variable hasn't changed. It may be related to how the provider handles state for these computed attributes.
- **Potential Workaround:** Consider adding `lifecycle { ignore_changes = [odb_network, odb_subnet] }` to the `google_oracle_database_autonomous_database` resource in `main.tf`.
- **Warning:** Use this workaround with caution. If the underlying network *does* change, ignoring these attributes might lead to a drift between the Terraform state and the actual infrastructure.
