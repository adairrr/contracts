use cosmwasm_schema::write_api;

use abstract_os::abstract_token::{ExecuteMsg, InstantiateMsg, MigrateMsg, QueryMsg};

fn main() {
    write_api! {
        instantiate: InstantiateMsg,
        query: QueryMsg,
        execute: ExecuteMsg,
        migrate: MigrateMsg,
    };
    // let mut out_dir = current_dir().unwrap();
    // out_dir.push("schema");
    // create_dir_all(&out_dir).unwrap();
    // remove_schemas(&out_dir).unwrap();

    // export_schema(&schema_for!(InstantiateMsg), &out_dir);
    // export_schema(&schema_for!(MigrateMsg), &out_dir);
    // export_schema(&schema_for!(ExecuteMsg), &out_dir);
    // export_schema(&schema_for!(QueryMsg), &out_dir);
    // export_schema(&schema_for!(AllowanceResponse), &out_dir);
    // export_schema(&schema_for!(BalanceResponse), &out_dir);
    // export_schema(&schema_for!(TokenInfoResponse), &out_dir);
    // export_schema(&schema_for!(MinterResponse), &out_dir);
    // export_schema(&schema_for!(AllAllowancesResponse), &out_dir);
    // export_schema(&schema_for!(AllAccountsResponse), &out_dir);
}