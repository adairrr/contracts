mod account_creation;
mod common_integration;
mod instantiate;
mod module_uploader;
mod upload;
mod verify;

pub mod env {
    use std::collections::HashMap;

    pub use super::{account_creation::init_os, common_integration::*, module_uploader::*};
    use super::{account_creation::init_primary_os, upload::upload_base_contracts};
    use abstract_sdk::core::{
        manager::{self as ManagerMsgs, ManagerModuleInfo},
        version_control::Core,
    };
    use anyhow::Result as AnyResult;
    use cosmwasm_std::{attr, to_binary, Addr, Uint128};
    use cw_multi_test::{App, AppResponse, Executor};
    use serde::Serialize;

    pub struct AbstractEnv {
        pub native_contracts: NativeContracts,
        pub code_ids: HashMap<String, u64>,
        pub account_store: HashMap<u32, Core>,
    }

    impl AbstractEnv {
        pub fn new(app: &mut App, sender: &Addr) -> Self {
            let (code_ids, native_contracts) = upload_base_contracts(app);
            let mut account_store: HashMap<u32, Core> = HashMap::new();

            init_os(app, sender, &native_contracts, &mut account_store)
                .expect("created first account");

            init_primary_os(app, sender, &native_contracts, &mut account_store).unwrap();

            app.update_block(|b| {
                b.time = b.time.plus_seconds(6);
                b.height += 1;
            });

            AbstractEnv {
                native_contracts,
                code_ids,
                account_store,
            }
        }
    }

    pub fn get_account_state(
        app: &App,
        account_store: &HashMap<u32, Core>,
        account_id: &u32,
    ) -> AnyResult<HashMap<String, Addr>> {
        let manager_addr: Addr = account_store.get(account_id).unwrap().manager.clone();
        // Check Account
        let mut resp: ManagerMsgs::ModuleInfosResponse = app.wrap().query_wasm_smart(
            &manager_addr,
            &ManagerMsgs::QueryMsg::ModuleInfos {
                start_after: None,
                limit: None,
            },
        )?;
        let mut state = HashMap::new();
        while !resp.module_infos.is_empty() {
            let mut last_module: Option<String> = None;
            for ManagerModuleInfo {
                address,
                id,
                version: _,
                ..
            } in resp.module_infos
            {
                last_module = Some(id.clone());
                state.insert(id, Addr::unchecked(address));
            }
            resp = app.wrap().query_wasm_smart(
                &manager_addr,
                &ManagerMsgs::QueryMsg::ModuleInfos {
                    start_after: last_module,
                    limit: None,
                },
            )?;
        }
        Ok(state)
    }

    pub fn exec_msg_on_manager<T: Serialize>(
        app: &mut App,
        sender: &Addr,
        manager_addr: &Addr,
        module_name: &str,
        encapsuled_msg: &T,
    ) -> AnyResult<AppResponse> {
        let msg = abstract_sdk::core::manager::ExecuteMsg::ExecOnModule {
            module_id: module_name.into(),
            exec_msg: to_binary(encapsuled_msg)?,
        };
        app.execute_contract(sender.clone(), manager_addr.clone(), &msg, &[])
    }

    /// Mint tokens
    pub fn mint_tokens(
        app: &mut App,
        owner: &Addr,
        token_instance: &Addr,
        amount: Uint128,
        to: String,
    ) {
        let msg = cw20::Cw20ExecuteMsg::Mint {
            recipient: to.clone(),
            amount,
        };
        let res = app
            .execute_contract(owner.clone(), token_instance.clone(), &msg, &[])
            .unwrap();
        assert_eq!(res.events[1].attributes[1], attr("action", "mint"));
        assert_eq!(res.events[1].attributes[2], attr("to", to));
        assert_eq!(res.events[1].attributes[3], attr("amount", amount));
    }

    pub fn _token_balance(app: &App, token_instance: &Addr, owner: &Addr) -> u128 {
        let balance: cw20::BalanceResponse = app
            .wrap()
            .query_wasm_smart(
                token_instance,
                &cw20_base::msg::QueryMsg::Balance {
                    address: owner.to_string(),
                },
            )
            .unwrap();
        balance.balance.u128()
    }
}
